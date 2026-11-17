// Original 24-bar 6/8 story cue: piano theme, woodwind answer, dark bridge, hopeful return.
import Foundation
import AVFoundation
struct Note { let tick:Int; let length:Int; let channel:Int; let pitch:UInt8; let velocity:UInt8 }
let rate=44100.0, bpm=144.0, ticksPerBeat=2.0
let tickSeconds=60.0/bpm/ticksPerBeat
let totalTicks=24*12
var notes=[Note]()
func add(_ ch:Int,_ pitch:Int,_ tick:Int,_ length:Int,_ velocity:Int) {
 notes.append(Note(tick:tick,length:length,channel:ch,pitch:UInt8(pitch),velocity:UInt8(velocity)))
}
let chords=[[48,55,59,64],[43,50,57,62],[45,52,55,60],[41,48,55,60],
[48,55,59,64],[40,47,55,62],[41,48,57,60],[43,50,55,62],
[45,52,55,60],[40,47,55,59],[41,48,52,57],[38,45,53,60],
[45,52,55,60],[41,48,56,60],[38,45,53,57],[40,47,56,62],
[48,55,59,64],[43,50,57,62],[45,52,55,60],[41,48,55,60],
[38,45,53,60],[43,50,55,62],[48,55,59,64],[43,50,55,62]]
// Each event is (offset, pitch, length). Rests and unequal note lengths shape phrases.
let phrases:[[(Int,Int,Int)]]=[
[(0,67,2),(2,72,3),(5,76,1),(6,74,4),(10,72,2)],
[(0,71,6),(7,69,2),(9,67,3)],
[(0,69,2),(2,72,2),(4,76,2),(6,79,5)],
[(0,77,3),(3,76,2),(5,72,1),(6,74,5)],
[(0,67,2),(2,72,3),(5,76,1),(6,79,4),(10,76,2)],
[(0,74,6),(7,71,2),(9,67,3)],
[(0,69,3),(3,72,3),(6,76,2),(8,74,2),(10,72,2)],
[(0,71,8),(10,67,2)],
[(0,72,4),(5,71,1),(6,69,5)],
[(0,67,6),(8,64,4)],
[(0,65,3),(3,69,3),(6,72,6)],
[(0,74,8),(9,72,3)],
[(0,69,3),(3,72,2),(5,71,1),(6,69,4),(10,64,2)],
[(0,68,5),(6,65,5)],
[(0,65,3),(3,69,3),(6,74,3),(9,72,3)],
[(0,71,4),(4,68,2),(6,64,5)],
[(0,67,2),(2,72,3),(5,76,1),(6,79,5)],
[(0,81,3),(3,79,2),(5,74,1),(6,71,5)],
[(0,76,3),(3,79,3),(6,84,4),(10,83,2)],
[(0,81,3),(3,79,3),(6,76,5)],
[(0,77,3),(3,76,2),(5,74,1),(6,72,4),(10,69,2)],
[(0,71,3),(3,74,3),(6,79,5)],
[(0,76,3),(3,74,3),(6,72,5)],
[(0,71,6),(8,67,3)]]
for bar in 0..<24 {
 let t=bar*12,c=chords[bar], dark=bar>=8 && bar<16
 let intensity=bar<4 ? 0 : (bar<8 ? 6 : (bar<16 ? -5 : 10))
 for (j,p) in c.enumerated() {
  if j==0 {add(0,p,t,5,51+intensity);add(2,p-12,t,11,43+intensity)}
  else if bar>=4 {add(3,p,t+j-1,12-j,39+intensity)}
 }
 // Three different accompaniment figures instead of a repeated arpeggio every bar.
 let pattern=bar%3==0 ? [0,3,6,8,10] : (bar%3==1 ? [0,4,6,9] : [0,2,5,6,9,11])
 for (k,offset) in pattern.enumerated() {
  add(bar<4 ? 0:4,c[1+k%3],t+offset,3,42+intensity+(k%2==0 ? 7:0))
 }
 let lead=bar<4 ? 0 : (dark ? 2:1)
 for (offset,pitch,length) in phrases[bar] {
  add(lead,pitch-(dark ? 12:0),t+offset,length,76+intensity-(offset%3)*3)
 }
 // Sparse piano replies and sustained inner voices leave breathing room for narration.
 if bar>=4 && bar%2==1 {add(0,c[2]+12,t+8,2,55);add(0,c[1]+12,t+10,2,48)}
 if bar>=16 && bar<22 {add(3,c[2]+12,t+6,5,40);if bar%2==0 {add(5,c[3]+12,t,3,44)}}
}
let engine=AVAudioEngine()
var samplers=[AVAudioUnitSampler]()
let programs:[UInt8]=[0,73,42,48,46,8] // strings, cello, horn, strings, drums, timpani
let volumes:[Float]=[0.80,0.62,0.48,0.30,0.38,0.20]
let bank=URL(fileURLWithPath:"/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
let format=AVAudioFormat(standardFormatWithSampleRate:rate,channels:2)!
for i in 0..<6 {
 let sampler=AVAudioUnitSampler();engine.attach(sampler)
 try sampler.loadSoundBankInstrument(at:bank,program:programs[i],bankMSB:121,bankLSB:0)
 engine.connect(sampler,to:engine.mainMixerNode,format:format)
 sampler.volume=volumes[i];sampler.stereoPan=[-12,15,-8,22,-25,30][i]
 samplers.append(sampler)
}
try engine.enableManualRenderingMode(.offline,format:format,maximumFrameCount:512)
try engine.start()
let output=URL(fileURLWithPath:CommandLine.arguments.count>1 ? CommandLine.arguments[1]:"/tmp/opening-score.wav")
let file=try AVAudioFile(forWriting:output,settings:format.settings)
let buffer=AVAudioPCMBuffer(pcmFormat:engine.manualRenderingFormat,frameCapacity:512)!
// Two repetitions allow note releases to flow across the exported loop boundary.
var on=[Int:[Note]](), off=[Int:[Note]]()
for repeatIndex in 0..<2 {
 for n in notes {
  let start=n.tick+repeatIndex*totalTicks
  on[start,default:[]].append(n);off[start+n.length,default:[]].append(n)
 }
}
for tick in 0..<(totalTicks*2) {
 for n in off[tick] ?? [] {samplers[n.channel].stopNote(n.pitch,onChannel:0)}
 for n in on[tick] ?? [] {samplers[n.channel].startNote(n.pitch,withVelocity:n.velocity,onChannel:0)}
 var remaining=Int(Double(tick+1)*tickSeconds*rate)-Int(Double(tick)*tickSeconds*rate)
 while remaining>0 {
  let count=AVAudioFrameCount(min(512,remaining))
  let status=try engine.renderOffline(count,to:buffer)
  if status == .success {if tick>=totalTicks {try file.write(from:buffer)};remaining-=Int(count)}
  else if status == .error {fatalError("Offline renderer failed")}
 }
}
engine.stop()
print("Rendered original opening theme: \(output.path)")
