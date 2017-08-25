//
//  Buzzer.swift
//  SwiftChip-8
//
//  Created by Brian Rojas on 8/24/17.
//  Copyright © 2017 Brian Rojas. All rights reserved.
//

import AudioToolbox

public enum BuzzerError: Error {
    
    case error(status: OSStatus)
    
}

public final class Buzzer {
    
    public enum Frequency: Float, CustomStringConvertible {
        case C4     = 261.63
        case Db4    = 277.18
        case D4     = 293.66
        case Eb4    = 311.13
        case E4     = 329.63
        case F4     = 349.23
        case Gb4    = 369.99
        case G4     = 392.00
        case Ab4    = 415.30
        case A4     = 440.00
        case Bb4    = 466.16
        case B4     = 493.88
        
        public var description: String {
            switch self {
            case .C4:
                return "C4"
            case .Db4:
                return "C♯4/D♭4"
            case .D4:
                return "D4"
            case .Eb4:
                return "D♯4/E♭4"
            case .E4:
                return "E4"
            case .F4:
                return "F4"
            case .Gb4:
                return "F♯4/G♭4"
            case .G4:
                return "G4"
            case .Ab4:
                return "G♯4/A♭4"
            case .A4:
                return "A4"
            case .Bb4:
                return "A♯4/B♭4"
            case .B4:
                return "B4"
            }
        }
    }
    
    private static let Samples = 44100
    
    private var isSounding = false
    
    private var component: AudioComponentInstance? = nil
    
    private let frequency: Frequency
    
    private var startingFrameCount: Float = 0.0
    
    init(frequency: Frequency) throws {
        self.frequency = frequency
        
        var defaultOutputDescription = AudioComponentDescription(componentType: kAudioUnitType_Output, componentSubType: kAudioUnitSubType_RemoteIO, componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0)
        
        let defaultOutput = AudioComponentFindNext(nil, &defaultOutputDescription)
        var error = AudioComponentInstanceNew(defaultOutput!, &component)
        if error != noErr {
            throw BuzzerError.error(status: error)
        }
        
        var input = AURenderCallbackStruct()
        input.inputProc = { (inRefCon, _, _, _, inNumberFrames, ioData) -> OSStatus in
            let buzzer = Unmanaged<Buzzer>.fromOpaque(inRefCon).takeUnretainedValue()
            
            let rawData = ioData?.pointee.mBuffers.mData
            let mutableData = rawData?.bindMemory(to: Float32.self, capacity: Int(inNumberFrames))
            let data = UnsafeMutableBufferPointer(start: mutableData, count: Int(inNumberFrames))

            var j = buzzer.startingFrameCount
            let cycleLength = Float(Buzzer.Samples) / buzzer.frequency.rawValue
            for frame in 0..<Int(inNumberFrames) {
                let value = sin(2.0 * Float.pi * (j / cycleLength))
                data[frame] = value
                
                j += 1.0
                if j > cycleLength {
                    j -= cycleLength
                }
            }
            
            buzzer.startingFrameCount = j
            return noErr
        }
        input.inputProcRefCon = UnsafeMutableRawPointer(Unmanaged<Buzzer>.passUnretained(self).toOpaque())
        error = AudioUnitSetProperty(component!, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &input, UInt32(MemoryLayout.size(ofValue: input)))
        if error != noErr {
            throw BuzzerError.error(status: error)
        }
        
        var asbd = AudioStreamBasicDescription()
        asbd.mSampleRate = Float64(Buzzer.Samples)
        asbd.mFormatID = kAudioFormatLinearPCM
        asbd.mFormatFlags =  kLinearPCMFormatFlagIsFloat | kLinearPCMFormatFlagIsPacked
        asbd.mBitsPerChannel = 32
        asbd.mChannelsPerFrame = 1
        asbd.mBytesPerFrame = asbd.mChannelsPerFrame * 4
        asbd.mFramesPerPacket = 1
        asbd.mBytesPerPacket = asbd.mFramesPerPacket * asbd.mBytesPerFrame
        error = AudioUnitSetProperty(component!, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &asbd, UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        if error != noErr {
            throw BuzzerError.error(status: error)
        }
        
        error = AudioUnitInitialize(component!)
        if error != noErr {
            throw BuzzerError.error(status: error)
        }
    }
    
    deinit {
        do {
            try stop()
        } catch {}
        AudioUnitUninitialize(component!)
        AudioComponentInstanceDispose(component!)
    }
    
    func sound() throws {
        guard isSounding == false else {
            return
        }
        isSounding = true
        
        let error = AudioOutputUnitStart(component!)
        if error != noErr {
            throw BuzzerError.error(status: error)
        }
    }
    
    func stop() throws {
        guard isSounding == true else {
            return
        }
        isSounding = false
        
        let error = AudioOutputUnitStop(component!)
        if error != noErr {
            throw BuzzerError.error(status: error)
        }
    }
    
}
