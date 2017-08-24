//
//  Chip8.swift
//  SwiftChip-8
//
//  Created by Brian Rojas on 8/12/17.
//  Copyright © 2017 Brian Rojas. All rights reserved.
//

import Foundation

// http://devernay.free.fr/hacks/chip8/C8TECH10.HTM

public protocol Chip8Delegate {
    
    func chip8(chip8: Chip8, errorOccured err: Chip8Error)
    
    func chip8SoundBuzzer(chip8: Chip8)
    
    func chip8StopBuzzer(chip8: Chip8)
    
}

public enum Chip8Error: Error {
    
    case invalidROMFile(url: URL)
    
    case invalidOpCode(opCode: String)
    
}

public final class Chip8 {
    
    public static var DisplayWidth = 64
    
    public static var DisplayHeight = 32
    
    public var delegate: Chip8Delegate?
    
    public var speed: Int = 12
    
    private var display = [UInt8](repeating: 0, count: (Chip8.DisplayWidth * Chip8.DisplayHeight))
    
    private static var MemoryMaxSize = 4096
    
    private static var MemoryStart = 0x200
    
    private var memory: [UInt8]
    
    private var V = [Int](repeating: 0, count: 16)
    
    private var I: Int = 0
    
    private var pc = Chip8.MemoryStart
    
    private var sp = 0
    
    private var stack = [Int](repeating:0, count: 16)
    
    private var delayTimer = 0
    
    private var soundTimer = 0
    
    private var lastFrameTime: TimeInterval = 0
    
    private var isHalted = false
    
    private var registerForKeyPress = 0
    
    private var buttonStates = [Bool](repeating: false, count: 16)
    
    private let hexSprites: [UInt8] = [
        0xF0, 0x90, 0x90, 0x90, 0xF0,
        0x20, 0x60, 0x20, 0x20, 0x70,
        0xF0, 0x10, 0xF0, 0x80, 0xF0,
        0xF0, 0x10, 0xF0, 0x10, 0xF0,
        0x90, 0x90, 0xF0, 0x10, 0x10,
        0xF0, 0x80, 0xF0, 0x10, 0xF0,
        0xF0, 0x80, 0xF0, 0x90, 0xF0,
        0xF0, 0x10, 0x20, 0x40, 0x40,
        0xF0, 0x90, 0xF0, 0x90, 0xF0,
        0xF0, 0x90, 0xF0, 0x10, 0xF0,
        0xF0, 0x90, 0xF0, 0x90, 0x90,
        0xE0, 0x90, 0xE0, 0x90, 0xE0,
        0xF0, 0x80, 0x80, 0x80, 0xF0,
        0xE0, 0x90, 0x90, 0x90, 0xE0,
        0xF0, 0x80, 0xF0, 0x80, 0xF0,
        0xF0, 0x80, 0xF0, 0x80, 0x80
    ]
    
    public init(program: URL) throws {
        memory = [UInt8](repeating: 0, count: Chip8.MemoryMaxSize)
        memory.replaceSubrange(0..<hexSprites.count, with: hexSprites)
        
        do {
            let data = try Data(contentsOf: program)
            memory.replaceSubrange(Chip8.MemoryStart..<(Chip8.MemoryStart+data.count), with: data)
        } catch {
            delegate?.chip8(chip8: self, errorOccured: .invalidROMFile(url: program))
        }
    }
    
    public func run() {
        var deltaTime = 1.0 / 60.0
        
        if lastFrameTime == 0 {
            lastFrameTime = Date().timeIntervalSince1970
        } else {
            let currFrameTime = Date().timeIntervalSince1970
            deltaTime = currFrameTime - lastFrameTime
            lastFrameTime = currFrameTime
        }
        
        let catchUpFrames = Int(max(1, round(Float(deltaTime) / Float(1.0 / 60.0))))
        updateTimers(catchUpFrames: catchUpFrames)
        runOpCodes(catchUpFrames: catchUpFrames)
    }
    
    public func press(button: Int) {
        buttonStates[button] = true
        
        if isHalted {
            V[registerForKeyPress] = button
            isHalted = false
        }
    }
    
    public func release(button: Int) {
        buttonStates[button] = false
    }
    
    public subscript(x: Int, y: Int) -> Bool {
        return display[y * Chip8.DisplayWidth + x] != 0
    }
    
    private func updateTimers(catchUpFrames: Int) {
        if delayTimer > 0 {
            delayTimer = max(0, delayTimer - catchUpFrames)
        }
        if soundTimer > 0 {
            soundTimer = max(0, soundTimer - catchUpFrames)
            delegate?.chip8SoundBuzzer(chip8: self)
        } else {
            delegate?.chip8StopBuzzer(chip8: self)
        }
    }
    
    private func runOpCodes(catchUpFrames: Int) {
        for _ in 0..<speed * catchUpFrames {
            if !isHalted {
                do {
                    try runOpCode()
                } catch {
                    isHalted = true
                    delegate?.chip8(chip8: self, errorOccured: error as! Chip8Error)
                }
            }
        }
    }
    
    private func runOpCode() throws {
        let opCode = (Int(memory[pc]) << 8) | Int(memory[pc + 1])
        let nnn = opCode & 0x0FFF
        let n = opCode & 0x000F
        let x = (opCode & 0x0F00) >> 8
        let y = (opCode & 0x00F0) >> 4
        let kk = opCode & 0x00FF
        pc += 2
        
        switch opCode & 0xF000 {
        case 0x0000:
            switch opCode & 0x00FF {
            case 0x00E0:
                for (i, _) in display.enumerated() {
                    display[i] = 0
                }
            case 0x00EE:
                sp -= 1
                pc = stack[sp]
            default:
                throw Chip8Error.invalidOpCode(opCode: String(format:"%2X", opCode))
            }
        case 0x1000:
            pc = nnn
        case 0x2000:
            stack[sp] = pc
            sp += 1;
            pc = nnn
        case 0x3000:
            if V[x] == kk {
                pc += 2
            }
        case 0x4000:
            if V[x] != kk {
                pc += 2
            }
        case 0x5000:
            if V[x] == V[y] {
                pc += 2
            }
        case 0x6000:
            V[x] = kk
        case 0x7000:
            V[x] = (V[x] + kk) & 0xFF
        case 0x8000:
            switch opCode & 0x000F {
            case 0x0000:
                V[x] = V[y]
            case 0x0001:
                V[x] |= V[y]
            case 0x0002:
                V[x] &= V[y]
            case 0x0003:
                V[x] ^= V[y]
            case 0x0004:
                let sum = V[x] + V[y]
                V[0xF] = sum > 0xFF ? 1 : 0
                V[x] = sum & 0xFF
            case 0x0005:
                let diff = V[x] - V[y]
                V[0xF] = diff >= 0 ? 1 : 0
                V[x] = diff & 0xFF
            case 0x0006:
                V[0xF] = V[x] & 0x01
                V[x] >>= 1
            case 0x0007:
                let diff = V[y] - V[x]
                V[0xF] = diff >= 0 ? 1 : 0
                V[x] = diff & 0xFF
            case 0x0008:
                V[0xF] = (V[x] >> 7) & 0x01
                V[x] <<= 1
            default:
                throw Chip8Error.invalidOpCode(opCode: String(format:"%2X", opCode))
            }
        case 0x9000:
            if V[x] != V[y] {
                pc += 2
            }
        case 0xA000:
            I = nnn
        case 0xB000:
            pc = nnn + V[0]
        case 0xC000:
            V[x] = Int(arc4random_uniform(256)) & kk
        case 0xD000:
            let width = 8
            let height = n
            for spriteY in 0..<height {
                let row = Int(memory[I + spriteY])
                for spriteX in 0..<width {
                    guard ((row >> (width - 1 - spriteX)) & 0x01) == 1 else {
                        continue
                    }
                    let erased = drawToDisplay(x: V[x] + spriteX, y: V[y] + spriteY)
                    V[0xF] = erased ? 1 : 0
                }
            }
        case 0xE000:
            switch (opCode & 0x00FF) {
            case 0x009E:
                if buttonStates[V[x]] {
                    pc += 2
                }
            case 0x0A1:
                if !buttonStates[V[x]] {
                    pc += 2
                }
            default:
                throw Chip8Error.invalidOpCode(opCode: String(format:"%2X", opCode))
            }
        case 0xF000:
            switch opCode & 0x00FF {
            case 0x0007:
                V[x] = delayTimer
            case 0x000A:
                registerForKeyPress = x
                isHalted = true
            case 0x0015:
                delayTimer = V[x]
            case 0x0018:
                soundTimer = V[x]
            case 0x001E:
                I += V[x] & 0xFFFF
            case 0x0029:
                I = (V[x] * 5) & 0xFFFF
            case 0x0033:
                memory[I + 0] = UInt8(V[x] / 100 % 10)
                memory[I + 1] = UInt8(V[x] / 10 % 10)
                memory[I + 2] = UInt8(V[x] / 1 % 10)
            case 0x0055:
                for i in 0...x {
                    memory[I + i] = UInt8(V[i] & 0xFF)
                }
            case 0x0065:
                for i in 0...x {
                    V[i] = Int(memory[I + i])
                }
            default:
                throw Chip8Error.invalidOpCode(opCode: String(format:"%2X", opCode))
            }
        default:
            throw Chip8Error.invalidOpCode(opCode: String(format:"%2X", opCode))
        }
    }
    
    private func drawToDisplay(x: Int, y: Int) -> Bool {
        var x = x
        var y = y
        
        x %= Chip8.DisplayWidth
        y %= Chip8.DisplayHeight
        
        let i = y * Chip8.DisplayWidth + x
        display[i] ^= 1
        return display[i] == 0
    }
    
}
