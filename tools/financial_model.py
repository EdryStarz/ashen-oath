"""24-month expected-value cohort model; assumptions, NOT observed performance.

Run: python tools/financial_model.py
Writes docs/financial_model.json. No external package or account is required.
"""

from __future__ import annotations

import argparse
import json
import math
from dataclasses import asdict, dataclass, replace
from pathlib import Path


@dataclass(frozen=True)
class Assumptions:
    name: str
    installs_month1: float
    install_growth: float
    activation: float
    retained_month1: float
    paid_conversion_of_retained: float
    monthly_churn: float
    annual_share: float
    annual_renewal: float
    retained_later_month_survival: float
    paid_acquisition_share: float
    cpi_usd: float
    refund_rate: float
    content_monthly_usd: float
    development_monthly_usd: float
    operations_monthly_usd: float
    support_per_active_month_usd: float
    setup_usd: float
    monthly_price_usd: float = 4.99
    annual_price_usd: float = 39.99
    updated_regions_revenue_share: float = 0.70
    updated_regions_subscription_service_fee: float = 0.10
    updated_regions_play_billing_fee: float = 0.05
    other_regions_subscription_fee: float = 0.15
    months: int = 24


SCENARIOS = [
    Assumptions("conservative", 1200, .06, .40, .30, .04, .13, .35, .40, .78,
                .15, .80, .05, 1000, 2000, 250, .03, 15000),
    Assumptions("base", 8000, .08, .55, .45, .075, .085, .40, .55, .85,
                .25, 1.10, .035, 3000, 4500, 600, .04, 35000),
    Assumptions("optimistic", 20000, .11, .65, .58, .10, .05, .45, .70, .90,
                .35, 1.50, .025, 7000, 9000, 1500, .05, 70000),
]


def validate(a: Assumptions) -> None:
    assert 1 <= a.months <= 120
    for key in ("activation", "retained_month1", "paid_conversion_of_retained",
                "monthly_churn", "annual_share", "annual_renewal",
                "retained_later_month_survival", "paid_acquisition_share",
                "refund_rate", "updated_regions_revenue_share",
                "updated_regions_subscription_service_fee",
                "updated_regions_play_billing_fee", "other_regions_subscription_fee"):
        assert 0 <= getattr(a, key) <= 1, key
    assert a.installs_month1 >= 0 and a.install_growth >= -1
    assert a.monthly_price_usd >= 0 and a.annual_price_usd >= 0


def model(a: Assumptions) -> dict:
    validate(a)
    # Each installation cohort is offered conversion once, in its second month.
    installs = [a.installs_month1 * (1 + a.install_growth) ** i
                for i in range(a.months)]
    activated = [x * a.activation for x in installs]
    newly_paid = [0.0] + [x * a.retained_month1 * a.paid_conversion_of_retained
                          for x in activated[:-1]]
    fee_rate = (a.updated_regions_revenue_share *
                (a.updated_regions_subscription_service_fee +
                 a.updated_regions_play_billing_fee) +
                (1 - a.updated_regions_revenue_share) *
                a.other_regions_subscription_fee)
    rows = []
    cumulative_cash = 0.0
    gross_to_date = 0.0
    goal_month = None
    for month in range(a.months):
        monthly_invoices = 0.0
        annual_invoices = 0.0
        annual_active = 0.0
        for cohort in range(month + 1):
            age = month - cohort
            monthly_invoices += (newly_paid[cohort] * (1 - a.annual_share)
                                 * (1 - a.monthly_churn) ** age)
            annual_cohort_active = (newly_paid[cohort] * a.annual_share
                                    * a.annual_renewal ** (age // 12))
            annual_active += annual_cohort_active
            if age % 12 == 0:
                annual_invoices += annual_cohort_active
        action_active = activated[month] + sum(
            activated[cohort] * a.retained_month1 *
            a.retained_later_month_survival ** (month - cohort - 1)
            for cohort in range(month)
        )
        monthly_cash = monthly_invoices * a.monthly_price_usd
        annual_cash = annual_invoices * a.annual_price_usd
        gross_cash = monthly_cash + annual_cash
        # Service delivered evenly over 12 months. This is an illustrative
        # accrual bridge, not audited revenue recognition or a tax calculation.
        annual_service_earned = annual_active * a.annual_price_usd / 12
        refund_cash = gross_cash * a.refund_rate
        after_refunds = gross_cash - refund_cash
        platform_fees = after_refunds * fee_rate
        paid_installs = installs[month] * a.paid_acquisition_share
        acquisition_cost = paid_installs * a.cpi_usd
        support_cost = action_active * a.support_per_active_month_usd
        setup = a.setup_usd if month == 0 else 0.0
        total_costs = (acquisition_cost + support_cost + a.content_monthly_usd +
                       a.development_monthly_usd + a.operations_monthly_usd + setup)
        net_platform_receipts = after_refunds - platform_fees
        cash_after_costs = net_platform_receipts - total_costs
        cumulative_cash += cash_after_costs
        gross_to_date += gross_cash
        if goal_month is None and gross_to_date >= 1_000_000:
            goal_month = month + 1
        rows.append({
            "month": month + 1,
            "installs": installs[month],
            "activated": activated[month],
            "eligible_retained_previous_cohort": (activated[month - 1] * a.retained_month1
                                                  if month else 0),
            "action_active_estimate": action_active,
            "new_payers": newly_paid[month],
            "new_monthly_payers": newly_paid[month] * (1 - a.annual_share),
            "new_annual_payers": newly_paid[month] * a.annual_share,
            "monthly_invoices": monthly_invoices,
            "annual_invoices": annual_invoices,
            "annual_active_entitlements": annual_active,
            "monthly_gross_cash_usd": monthly_cash,
            "annual_gross_cash_usd": annual_cash,
            "gross_cash_usd": gross_cash,
            "annual_service_earned_gross_usd": annual_service_earned,
            "service_earned_gross_usd": monthly_cash + annual_service_earned,
            "refunds_usd": refund_cash,
            "platform_fees_usd": platform_fees,
            "net_platform_receipts_usd": net_platform_receipts,
            "paid_installs": paid_installs,
            "acquisition_cost_usd": acquisition_cost,
            "content_cost_usd": a.content_monthly_usd,
            "development_cost_usd": a.development_monthly_usd,
            "operations_cost_usd": a.operations_monthly_usd,
            "support_cost_usd": support_cost,
            "setup_cost_usd": setup,
            "total_costs_usd": total_costs,
            "cash_after_costs_usd": cash_after_costs,
            "cumulative_cash_after_costs_usd": cumulative_cash,
        })
    flow_keys = [key for key in rows[0] if key not in {
        "month", "action_active_estimate", "annual_active_entitlements",
        "cumulative_cash_after_costs_usd"}]
    totals = {key: sum(row[key] for row in rows) for key in flow_keys}
    totals.update({
        "action_active_month24": rows[-1]["action_active_estimate"],
        "annual_active_entitlements_month24": rows[-1]["annual_active_entitlements"],
        "monthly_payers_month24": rows[-1]["monthly_invoices"],
        "gross_annual_unserved_balance_usd": (
            totals["annual_gross_cash_usd"] - totals["annual_service_earned_gross_usd"]),
        "net_of_refunds_annual_unserved_balance_usd": (
            (totals["annual_gross_cash_usd"] - totals["annual_service_earned_gross_usd"])
            * (1 - a.refund_rate)),
        "peak_financing_need_usd": max(0.0, -min(row["cumulative_cash_after_costs_usd"]
                                                 for row in rows)),
        "goal_1m_gross_cash_month": goal_month,
        "effective_subscription_platform_fee": fee_rate,
        "gross_cash_goal_fraction": totals["gross_cash_usd"] / 1_000_000,
    })
    return {"assumptions": asdict(a), "months": rows, "totals": totals}


def sensitivity(a: Assumptions) -> list[dict]:
    base = model(a)["totals"]
    result = []
    for key in ("installs_month1", "install_growth", "activation", "retained_month1",
                "paid_conversion_of_retained", "monthly_churn", "annual_renewal", "cpi_usd"):
        for factor in (.8, 1.2):
            changed = replace(a, **{key: getattr(a, key) * factor})
            totals = model(changed)["totals"]
            result.append({"parameter": key, "relative_change": factor - 1,
                           "gross_cash_usd": totals["gross_cash_usd"],
                           "gross_cash_change_pct": (totals["gross_cash_usd"] /
                                                      base["gross_cash_usd"] - 1) * 100,
                           "cash_after_costs_usd": totals["cash_after_costs_usd"],
                           "cash_after_costs_change_usd": totals["cash_after_costs_usd"] -
                                                          base["cash_after_costs_usd"]})
    return result


def self_test() -> int:
    checks = 0
    # One install cohort, every activated/retained user converts the next month.
    unit = replace(SCENARIOS[1], installs_month1=1, install_growth=-1,
                   activation=1, retained_month1=1, paid_conversion_of_retained=1,
                   annual_share=0, monthly_churn=0)
    monthly = model(unit)
    assert monthly["months"][0]["new_payers"] == 0
    assert monthly["totals"]["new_payers"] == 1
    assert monthly["totals"]["monthly_invoices"] == 23
    assert monthly["totals"]["annual_invoices"] == 0
    checks += 4
    annual = model(replace(unit, annual_share=1, annual_renewal=1))
    assert annual["totals"]["annual_invoices"] == 2
    assert annual["totals"]["monthly_invoices"] == 0
    assert annual["months"][1]["annual_invoices"] == 1
    assert annual["months"][13]["annual_invoices"] == 1
    assert math.isclose(annual["totals"]["gross_annual_unserved_balance_usd"],
                        unit.annual_price_usd / 12)
    checks += 5
    churned = model(replace(unit, monthly_churn=1))
    assert churned["totals"]["monthly_invoices"] == 1
    nonrenew = model(replace(unit, annual_share=1, annual_renewal=0))
    assert nonrenew["totals"]["annual_invoices"] == 1
    assert nonrenew["totals"]["annual_active_entitlements_month24"] == 0
    zero = model(replace(unit, paid_conversion_of_retained=0))
    assert zero["totals"]["gross_cash_usd"] == 0
    checks += 4
    for assumptions in SCENARIOS:
        report = model(assumptions)
        totals = report["totals"]
        assert math.isclose(totals["gross_cash_usd"], totals["monthly_gross_cash_usd"] +
                            totals["annual_gross_cash_usd"])
        assert math.isclose(totals["new_payers"], totals["new_monthly_payers"] +
                            totals["new_annual_payers"])
        assert math.isclose(totals["cash_after_costs_usd"], totals["gross_cash_usd"] -
                            totals["refunds_usd"] - totals["platform_fees_usd"] -
                            totals["total_costs_usd"])
        assert totals["gross_annual_unserved_balance_usd"] >= 0
        checks += 4
    return checks


def rounded(value):
    if isinstance(value, float):
        return round(value, 6)
    if isinstance(value, list):
        return [rounded(x) for x in value]
    if isinstance(value, dict):
        return {key: rounded(x) for key, x in value.items()}
    return value


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--test-only", action="store_true")
    args = parser.parse_args()
    checks = self_test()
    print(f"FINANCIAL MODEL: {checks} assertions passed")
    if args.test_only:
        return
    scenarios = {a.name: model(a) for a in SCENARIOS}
    report = {
        "as_of": "2026-10-08", "currency": "USD", "horizon_months": 24,
        "status": "assumptions_only_not_forecast_or_user_research",
        "goal": "1000000 gross billed cash excluding sales tax, before refunds and costs",
        "counts": "fractional expected cohort values, not measured people",
        "limitations": ["No payment integration exists in prototype", "No sales/income tax model",
                        "No payment settlement lag or bad debt", "No plan switches or reacquisition",
                        "Refunds are receipt adjustments; churn models subscriber loss separately",
                        "Acquisition/content/development budgets are unvalidated assumptions",
                        "Regional fee inputs verified on 2026-10-08; future changes require updates"],
        "self_tests_passed": checks, "scenarios": scenarios,
        "base_sensitivity": sensitivity(SCENARIOS[1]),
        "base_installs_month1_for_1m_at_fixed_rates": (SCENARIOS[1].installs_month1 *
            1_000_000 / scenarios["base"]["totals"]["gross_cash_usd"]),
    }
    output = Path(__file__).resolve().parents[1] / "docs" / "financial_model.json"
    output.write_text(json.dumps(rounded(report), ensure_ascii=False, indent=2) + "\n",
                      encoding="utf-8")
    for name, scenario in scenarios.items():
        totals = scenario["totals"]
        print(f"{name}: installs={totals['installs']:,.0f}; "
              f"new_payers={totals['new_payers']:,.0f}; "
              f"gross=${totals['gross_cash_usd']:,.0f}; "
              f"cash_after_costs=${totals['cash_after_costs_usd']:,.0f}; "
              f"annual_unserved=${totals['gross_annual_unserved_balance_usd']:,.0f}")
    print(output)


if __name__ == "__main__":
    main()
