'use strict';
const quests=[...document.querySelectorAll('.quest')];
quests.forEach(button=>button.addEventListener('click',()=>{
 button.setAttribute('aria-pressed',button.getAttribute('aria-pressed')==='true'?'false':'true');
 const xp=quests.filter(q=>q.getAttribute('aria-pressed')==='true').length*20;
 document.querySelector('#xp-value').textContent=`${xp} / 60 XP`;
 document.querySelector('.xp-fill').style.width=`${xp/60*100}%`;
 document.querySelector('[role="progressbar"]').setAttribute('aria-valuenow',xp);
}));
const dialog=document.querySelector('#screenshot-dialog');
document.querySelectorAll('.screen').forEach(button=>button.addEventListener('click',()=>{
 const image=dialog.querySelector('img');image.src=button.dataset.image;image.alt=button.getAttribute('aria-label');dialog.showModal();
}));
dialog.querySelector('[data-close]').addEventListener('click',()=>dialog.close());
dialog.addEventListener('click',event=>{if(event.target===dialog)dialog.close();});
document.querySelector('.share').addEventListener('click',async()=>{
 const status=document.querySelector('.share-status');
 const url=new URL(location.href);url.hash='';
 try{
  if(navigator.share){await navigator.share({title:document.title,url:url.href});}
  else{await navigator.clipboard.writeText(url.href);status.textContent=document.body.dataset.copied;}
 }catch(error){if(error.name!=='AbortError')status.textContent=`${document.body.dataset.shareFallback} ${url.href}`;}
});
