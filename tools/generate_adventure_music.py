import math,wave,array,random
sr=22050; beat=.5; bars=24; dur=bars*4*beat; out=[0.0]*int(sr*dur)
rng=random.Random(18)
def note(m,start,length,amp,kind):
 f=440*2**((m-69)/12); a=int(start*sr); n=int(length*sr)
 for j in range(n):
  if a+j>=len(out):break
  t=j/sr; env=min(1,t/.04)*min(1,(length-t)/.16)
  if kind=='harp': v=(math.sin(2*math.pi*f*t)+.25*math.sin(4*math.pi*f*t))*math.exp(-t*4)
  elif kind=='flute':v=math.sin(2*math.pi*f*t+.015*math.sin(2*math.pi*5*t))+.12*math.sin(4*math.pi*f*t)
  else:v=.7*math.sin(2*math.pi*f*t)+.2*math.sin(2*math.pi*f*1.003*t)+.1*math.sin(4*math.pi*f*t)
  out[a+j]+=amp*env*v
chords=[[48,52,55],[43,47,50],[45,48,52],[41,45,48],[48,52,55],[45,48,52],[41,45,48],[43,47,50]]
mel=[[72,76,79,76],[74,71,67,71],[72,76,81,79],[77,76,74,72],[76,79,84,83],[81,79,76,72],[74,77,76,72],[71,74,79,74]]
for b in range(bars):
 t=b*2;c=chords[b%8]
 for m in c:note(m,t,2,.035,'strings')
 for k in range(8):note(c[[0,1,2,1,0,2,1,2][k]]+12,t+k*.25,.7,.10,'harp')
 for k,m in enumerate(mel[b%8]):note(m+(0 if b<16 else -12),t+k*.5,.45,.085,'flute')
# Short room reflections and gentle saturation, no external samples.
for delay,gain in [(int(sr*.12),.16),(int(sr*.23),.08)]:
 for i in range(len(out)-1,delay,-1):out[i]+=out[i-delay]*gain
pcm=array.array('h',(int(math.tanh(v)*24000) for v in out))
with wave.open('assets/music/morning_adventure.wav','wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(sr);w.writeframes(pcm.tobytes())
