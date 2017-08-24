//
//  Buzzer.swift
//  SwiftChip-8
//
//  Created by Brian Rojas on 8/24/17.
//  Copyright © 2017 Brian Rojas. All rights reserved.
//

import AudioToolbox

public enum BuzzerError: Error {
    
    case initError(status: OSStatus)
    
    case soundError(status: OSStatus)
    
    case stopError(status: OSStatus)
    
}

public final class Buzzer {
    
    public enum Frequency: Float {
        case C4 = 261.63
        case A4 = 440.00
    }
    
    private static let Samples = 44100
    
    private var isSounding = false
    
    private var component: AudioComponentInstance? = nil
    
    private let frequency: Frequency
    
    init(frequency: Frequency) throws {
        self.frequency = frequency
        
        var defaultOutputDescription = AudioComponentDescription(componentType: kAudioUnitType_Output, componentSubType: kAudioUnitSubType_RemoteIO, componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0)
        
        let defaultOutput = AudioComponentFindNext(nil, &defaultOutputDescription)
        var error = AudioComponentInstanceNew(defaultOutput!, &component)
        if error != noErr {
            throw BuzzerError.initError(status: error)
        }
        
        var input = AURenderCallbackStruct()
        input.inputProc = { (inRefCon, _, _, _, inNumberFrames, ioData) -> OSStatus in
            let buzzer = Unmanaged<Buzzer>.fromOpaque(inRefCon).takeUnretainedValue()
            
            let rawData = ioData?.pointee.mBuffers.mData
            let mutableData = rawData?.bindMemory(to: Int16.self, capacity: Int(inNumberFrames))
            let buffer = UnsafeMutableBufferPointer(start: mutableData, count: Int(inNumberFrames))
            
            let wavelengthInSamples = Float(Buzzer.Samples) / buzzer.frequency.rawValue
            
            for frame in 0..<inNumberFrames {
                let sample = Int16(Float(Int16.max) * sin(2 * Float.pi * (Float(frame) / wavelengthInSamples))).bigEndian
                buffer[Int(frame)] = sample
            }
            return 0
        }
        input.inputProcRefCon = UnsafeMutableRawPointer(Unmanaged<Buzzer>.passUnretained(self).toOpaque())
        error = AudioUnitSetProperty(component!, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &input, UInt32(MemoryLayout.size(ofValue: input)))
        if error != noErr {
            throw BuzzerError.initError(status: error)
        }
        
        var asbd = AudioStreamBasicDescription()
        asbd.mSampleRate = Float64(Buzzer.Samples)
        asbd.mFormatID = kAudioFormatLinearPCM
        asbd.mFormatFlags = kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked
        asbd.mBitsPerChannel = 16
        asbd.mChannelsPerFrame = 1
        asbd.mBytesPerFrame = asbd.mChannelsPerFrame * 2
        asbd.mFramesPerPacket = 1
        asbd.mBytesPerPacket = asbd.mFramesPerPacket * asbd.mBytesPerFrame
        error = AudioUnitSetProperty(component!, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &asbd, UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        if error != noErr {
            throw BuzzerError.initError(status: error)
        }
        
        error = AudioUnitInitialize(component!)
        if error != noErr {
            throw BuzzerError.initError(status: error)
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
            throw BuzzerError.soundError(status: error)
        }
    }
    
    func stop() throws {
        guard isSounding == true else {
            return
        }
        isSounding = false
        
        let error = AudioOutputUnitStop(component!)
        if error != noErr {
            throw BuzzerError.stopError(status: error)
        }
    }
    
}
