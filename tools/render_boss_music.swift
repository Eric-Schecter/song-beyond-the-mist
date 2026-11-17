// Original battle score, rendered with the macOS General MIDI synthesizer.
import Foundation
import AVFoundation
struct Note { let tick:Int; let length:Int; let channel:Int; let pitch:UInt8; let velocity:UInt8 }
let rate=44100.0, bpm=152.0, ticksPerBeat=4.0
let tickSeconds=60.0/bpm/ticksPerBeat
let bars=32, totalTicks=32*16
var notes=[Note]()
func add(_ ch:Int,_ pitch:Int,_ tick:Int,_ length:Int,_ velocity:Int) {
 notes.append(Note(tick:tick,length:length,channel:ch,pitch:UInt8(pitch),velocity:UInt8(velocity)))
}
let chords=[[50,53,57],[46,50,53],[48,52,55],[45,49,52],[50,53,57],[43,46,50],[46,50,53],[45,49,52]]
let melody=[[74,77,81,79,77,76,74,72],[74,77,82,81,77,74,72,69],[72,76,79,84,83,79,76,72],[73,76,81,79,76,73,69,73],[74,81,86,84,81,79,77,74],[79,77,74,70,74,77,79,82],[82,81,77,74,77,81,82,84],[81,79,76,73,76,79,81,73]]
for bar in 0..<bars {
 let c=chords[bar%8], t=bar*16
 for j in 0..<16 {
  let p=c[[0,2,1,2][j%4]]+12
  add(0,p,t+j,1, j%4==0 ? 72:52)
 }
 for j in 0..<4 {add(1,c[0]-12,t+j*4,3,j==0 ? 85:69)}
 for j in 0..<8 {add(2,melody[bar%8][j]+(bar>=16 && bar<24 ? -12:0),t+j*2,2,j%2==0 ? 77:65)}
 if bar>=8 {
  for p in c {add(3,p+12,t,14,bar>=24 ? 55:40)}
 }
 for j in [0,8] {add(4,36,t+j,2,92)}
 for j in [4,12] {add(4,38,t+j,1,72)}
 for j in stride(from:0,to:16,by:2) {add(4,42,t+j,1,j%4==0 ? 46:31)}
 if bar%4==0 {add(4,49,t,8,48)}
 for j in [0,6,8,14] {add(5,c[0]-12,t+j,3,68)}
 if bar%8==7 {for j in 12..<16 {add(4,45+(j%2)*2,t+j,1,45+j*2)}}
}
let engine=AVAudioEngine()
var samplers=[AVAudioUnitSampler]()
let programs:[UInt8]=[48,42,60,48,0,47] // strings, cello, horn, strings, drums, timpani
let volumes:[Float]=[0.52,0.52,0.62,0.24,0.45,0.45]
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
let output=URL(fileURLWithPath:CommandLine.arguments.count>1 ? CommandLine.arguments[1]:"assets/music/guardian_battle.wav")
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
print("Rendered original 32-bar guardian battle loop: \(output.path)")
