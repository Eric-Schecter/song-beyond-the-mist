// Original leitmotif with A/A-prime/B/A form, rendered with system GM instruments.
import Foundation
import AVFoundation
struct Note { let tick:Int; let length:Int; let channel:Int; let pitch:UInt8; let velocity:UInt8 }
let dark=CommandLine.arguments.contains("history")
let rate=44100.0, bpm=dark ? 72.0 : 96.0, ticksPerBeat=4.0
let tickSeconds=60.0/bpm/ticksPerBeat
let totalTicks=16*16
var notes=[Note]()
func add(_ ch:Int,_ pitch:Int,_ tick:Int,_ length:Int,_ velocity:Int) {
 notes.append(Note(tick:tick,length:length,channel:ch,pitch:UInt8(pitch),velocity:UInt8(velocity)))
}
let major=[[48,52,55],[43,47,50],[45,48,52],[41,45,48],[48,52,55],[40,47,52],[41,45,48],[43,47,50],[45,48,52],[40,43,47],[41,45,48],[43,47,50],[48,52,55],[45,48,52],[41,45,48],[43,47,50]]
let minor=[[45,48,52],[40,47,52],[41,45,48],[38,45,53],[45,48,52],[43,47,50],[41,45,48],[40,44,47],[38,41,45],[45,48,52],[41,45,48],[40,44,47],[45,48,52],[41,45,48],[38,41,45],[40,44,47]]
// Recognizable rising fourth, repeated note and falling third; answered in bar 2.
let theme=[[67,72,72,76,74],[72,71,67,69,71],[69,76,76,79,76],[74,72,69,67,65],[67,72,72,79,76],[74,71,67,64,67],[65,69,72,76,74],[71,74,79,74,71],[76,81,79,76,72],[71,76,74,71,67],[69,77,76,72,69],[71,74,79,77,74],[79,84,84,83,79],[81,79,76,72,69],[77,76,72,69,65],[67,71,74,71,67]]
let starts=[0,3,6,8,12], lengths=[3,3,2,4,4]
for bar in 0..<16 {
 let c=(dark ? minor:major)[bar], t=bar*16
 for (k,p) in c.enumerated() {add(3,p+12,t+k,15-k,bar>=8 ? 57:44)}
 add(1,c[0]-12,t,14,66)
 for k in 0..<(dark ? 4:8) {
  add(0,c[[0,2,1,2][k%4]]+12,t+k*(dark ? 4:2),dark ? 5:3,k%4==0 ? 75:53)
 }
 for k in 0..<5 {
  var pitch=theme[bar][k]
  if dark {pitch-=3;if pitch%12==1 {pitch-=1}}
  add(2,pitch,t+starts[k],lengths[k],k==0 || k==3 ? 91:78)
 }
 if bar>=4 && !dark {add(5,c[2]+12,t+8,6,52)}
 if bar>=8 {add(4,36,t,1,40);add(4,42,t+8,1,30)}
 if dark && bar%4==3 {add(5,c[0]-12,t+12,4,48)}
}
let engine=AVAudioEngine()
var samplers=[AVAudioUnitSampler]()
let programs:[UInt8]=dark ? [46,42,68,48,0,47] : [46,42,73,48,0,60] // strings, cello, horn, strings, drums, timpani
let volumes:[Float]=[0.42,0.40,0.85,0.32,0.16,0.28]
let bank=URL(fileURLWithPath:"/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
let format=AVAudioFormat(standardFormatWithSampleRate:rate,channels:2)!
for i in 0..<6 {
 let sampler=AVAudioUnitSampler();engine.attach(sampler)
 try sampler.loadSoundBankInstrument(at:bank,program:programs[i],bankMSB:i==4 ? 120:121,bankLSB:0)
 engine.connect(sampler,to:engine.mainMixerNode,format:format)
 sampler.volume=volumes[i];sampler.stereoPan=[-20,0,12,25,0,-8][i]
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
