const {readFileSync}=require('node:fs');
const vm=require('node:vm');
const assert=require('node:assert/strict');
const source=readFileSync('tools/web_shell.html','utf8').split('<script>')[1].split('</script>')[0].replace('$GODOT_CONFIG',JSON.stringify({executable:'index',mainPack:'game-test.pck'}));
async function run(fail=false){
 const elements=Object.fromEntries(['canvas','play','progress','status','launch','error'].map(id=>[id,{style:{},hidden:id==='play',disabled:true,removeAttribute(){},addEventListener(event,fn){this[event]=fn;},remove(){this.removed=true;},focus(){this.focused=true;}}]));
 const calls=[];const window={};
 class Engine{init(){calls.push('init');return Promise.resolve();}preloadFile(p){calls.push(p);return Promise.resolve();}async start(options){calls.push(options.args);if(fail)throw Error('startup failed');}}
 vm.runInNewContext(source,{window,Engine,document:{getElementById:id=>elements[id]},requestAnimationFrame:fn=>fn()});
 await new Promise(resolve=>setImmediate(resolve));
 assert.equal(elements.play.disabled,true);
 assert.equal(elements.launch.removed,undefined);
 assert.ok(calls[2].includes('--web-cover'));
 if(fail){assert.match(elements.error.textContent,/startup failed/);window.songGameReady();assert.equal(elements.play.disabled,true);return;}
 elements.play.click();assert.equal(window.songCoverEntered,false);
 window.songGameReady();assert.equal(elements.play.disabled,false);
 elements.play.click();assert.equal(window.songCoverEntered,true);
 assert.equal(elements.launch.removed,true);assert.equal(elements.canvas.focused,true);
 assert.equal(calls.length,3,'click must not restart or download resources');
}
(async()=>{await run();await run(true);console.log('PASS loader: render readiness, guarded click, no restart, startup error');})().catch(e=>{console.error(e);process.exitCode=1;});
