//
//  GameViewController.swift
//  SwiftChip-8
//
//  Created by Brian Rojas on 8/12/17.
//  Copyright © 2017 Brian Rojas. All rights reserved.
//

import UIKit
import QuartzCore
import GLKit

class GameViewController: UIViewController {
    
    var game: URL!
    
    fileprivate var interpreter: Chip8?
    
    fileprivate var buzzer: Buzzer?
    
    private var displayLink: CADisplayLink?
    
    fileprivate var vertexBuffer = GLuint()
    
    fileprivate var colorEffect = GLKBaseEffect()
    
    @IBOutlet weak var gameView: GLKView!

    @IBOutlet var buttons: [UIButton]!
    
    deinit {
        glDeleteBuffers(1, &vertexBuffer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = game.lastPathComponent
        setupKeyboard()
        setupChip8()
        setupBuzzer()
        setupSpeedSlider()
        setupGL()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(redraw(displayLink:)))
            displayLink?.add(to: .main, forMode: .defaultRunLoopMode)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        displayLink?.remove(from: .main, forMode: .defaultRunLoopMode)
    }
    
    @IBAction func didPressButton(_ sender: UIButton) {
        interpreter?.press(button: sender.tag)
    }
    
    @IBAction func didReleaseButton(_ sender: UIButton) {
        interpreter?.release(button: sender.tag)
    }
    
    @objc private func redraw(displayLink: CADisplayLink) {
        do {
            try interpreter?.run()
        } catch {
            alert(error: error)
        }
        gameView.display()
    }
    
    @objc private func adjustSpeed(sender: UISlider) {
        interpreter?.speed = Int(sender.value)
    }
    
    private func setupKeyboard() {
        let keymap = [
            0: 1,
            1: 2,
            2: 3,
            3: 0xC,
            4: 4,
            5: 5,
            6: 6,
            7: 0xD,
            8: 7,
            9: 8,
            10: 9,
            11: 0xE,
            12: 0xA,
            13: 0,
            14: 0xB,
            15: 0xF
        ]
        
        for (index, button) in buttons.enumerated() {
            let image = UIImage(named: String(format: "%X", keymap[index]!))?.withRenderingMode(.alwaysTemplate)
            button.setImage(image, for: .normal)
            button.tintColor = UIColor(colorLiteralRed: 1.0, green: 196.0/255.0, blue: 0.0, alpha: 1.0)
            button.backgroundColor = UIColor(colorLiteralRed: 176.0/255.0, green: 74.0/255.0, blue: 0.0, alpha: 1.0)
        }
    }
    
    private func setupChip8() {
        do {
            interpreter = try Chip8(program: game)
        } catch {
            alert(error: error)
        }
        interpreter?.delegate = self
    }
    
    private func setupBuzzer() {
        do {
            buzzer = try Buzzer(frequency: .A4)
        } catch {
            alert(error: error)
        }
    }
    
    private func setupSpeedSlider() {
        let speedSlider = UISlider()
        speedSlider.translatesAutoresizingMaskIntoConstraints = false
        speedSlider.minimumValue = 1
        speedSlider.maximumValue = 30
        speedSlider.value = Float(Chip8.DefaultSpeed)
        speedSlider.addTarget(self, action: #selector(adjustSpeed(sender:)), for: .valueChanged)
        let speedItem = UIBarButtonItem(customView: speedSlider)
        toolbarItems?.append(speedItem)
    }
    
    private func setupGL() {
        let context = EAGLContext(api: .openGLES2)!
        EAGLContext.setCurrent(context)
        
        colorEffect.transform.projectionMatrix = GLKMatrix4MakeOrtho(0.0, Float(Chip8.DisplayWidth), 0.0, Float(Chip8.DisplayHeight), -1.0, 1.0)
        colorEffect.useConstantColor = GLboolean(GL_TRUE)
        colorEffect.constantColor = GLKVector4Make(1.0, 196.0/255.0, 0.0, 1.0)
        
        let vertices: [Float32] = [
            -0.5, -0.5,
            0.5, 0.5,
            -0.5, 0.5,
            -0.5, -0.5,
            0.5, -0.5,
            0.5, 0.5,
        ]
        
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), vertices.count * MemoryLayout<Float32>.size, vertices, GLenum(GL_STATIC_DRAW))
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, nil)
        
        gameView.context = context
    }
    
    fileprivate func alert(error: Error) {
        var message = ""
        switch error {
        case Chip8Error.invalidOpCode(let opCode):
            message = "Invalid op code: \(opCode)"
        case Chip8Error.invalidROMFile(let url):
            message = "Invalid ROM file: \(url)"
        case BuzzerError.initError(let status):
            message = "Buzzer error: \(status)"
        case BuzzerError.soundError(let status):
            message = "Buzzer error: \(status)"
        case BuzzerError.stopError(let status):
            message = "Buzzer error: \(status)"
        default:
            message = "Other error occured: \(error.localizedDescription)"
        }
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
}

extension GameViewController: Chip8Delegate {
    
    func chip8SoundBuzzer(chip8: Chip8) {
        do {
            try buzzer?.sound()
        } catch {
            alert(error: error)
        }
    }
    
    func chip8StopBuzzer(chip8: Chip8) {
        do {
            try buzzer?.stop()
        } catch {
            alert(error: error)
        }
    }
    
}

extension GameViewController: GLKViewDelegate {
    
    func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClearColor(176.0/255.0, 74.0/255.0, 0.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        for y in 0..<Chip8.DisplayHeight {
            for x in 0..<Chip8.DisplayWidth {
                guard let interpreter = interpreter, interpreter[x, y] else {
                    continue
                }
                var transform = GLKMatrix4MakeTranslation(0.0, Float(Chip8.DisplayHeight), 0.0)
                transform = GLKMatrix4Scale(transform, 1.0, -1.0, 1.0)
                transform = GLKMatrix4Translate(transform, Float(x) + 0.5, Float(y) + 0.5, 0.0)
                colorEffect.transform.modelviewMatrix = transform
                colorEffect.prepareToDraw()
                glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
            }
        }
    }
    
}
