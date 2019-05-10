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
    
    private var secondWindow: UIWindow?
    
    private var secondGameView: GLKView?
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UIScreen.screens.count > 1 {
            setupSecondScreen()
        }
        
        NotificationCenter.default.addObserver(forName: UIScreen.didConnectNotification, object: nil, queue: OperationQueue.main) { _ in
            self.setupSecondScreen()
        }
        
        NotificationCenter.default.addObserver(forName: UIScreen.didDisconnectNotification, object: nil, queue: OperationQueue.main) { _ in
            self.removeSecondScreen()
        }
        
        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(redraw(displayLink:)))
            displayLink?.add(to: .main, forMode: RunLoop.Mode.default)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        displayLink?.remove(from: .main, forMode: RunLoop.Mode.default)
        
        if UIScreen.screens.count > 1 {
            removeSecondScreen()
        }
        
        NotificationCenter.default.removeObserver(self)
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
        
        if let secondGameView = secondGameView {
            secondGameView.display()
        }
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
            button.tintColor = SettingsManager.instance.pixelColor
            button.backgroundColor = SettingsManager.instance.backgroundColor
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
            buzzer = try Buzzer(frequency: SettingsManager.instance.buzzerNote)
        } catch {
            alert(error: error)
        }
        buzzer?.volume = SettingsManager.instance.buzzerVolume
    }
    
    private func setupSpeedSlider() {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 34))
        toolbarItems?.append(UIBarButtonItem(customView: containerView))
        
        let speedSlider = UISlider()
        speedSlider.minimumValue = 1
        speedSlider.maximumValue = 30
        speedSlider.value = Float(Chip8.DefaultSpeed)
        speedSlider.addTarget(self, action: #selector(adjustSpeed(sender:)), for: .valueChanged)
        containerView.addSubview(speedSlider)
    }
    
    private func setupGL() {
        let context = EAGLContext(api: .openGLES2)!
        EAGLContext.setCurrent(context)
        
        colorEffect.transform.projectionMatrix = GLKMatrix4MakeOrtho(0.0, Float(Chip8.DisplayWidth), 0.0, Float(Chip8.DisplayHeight), -1.0, 1.0)
        colorEffect.useConstantColor = GLboolean(GL_TRUE)
        colorEffect.constantColor = SettingsManager.instance.pixelColor.glkVector4
        
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
    
    private func setupSecondScreen() {
        guard secondWindow == nil && secondGameView == nil else {
            return
        }
        
        let secondScreen = UIScreen.screens[1]
        
        secondWindow = UIWindow(frame: secondScreen.bounds)
        guard let secondWindow = secondWindow else {
            return
        }
        
        secondWindow.screen = secondScreen
        
        secondGameView = GLKView(frame: secondWindow.bounds, context: gameView.context)
        guard let secondGameView = secondGameView else {
            return
        }
        
        secondGameView.delegate = self
        secondWindow.addSubview(secondGameView)
        
        secondWindow.isHidden = false
    }
    
    private func removeSecondScreen() {
        secondGameView?.removeFromSuperview()
        secondGameView = nil
        secondWindow?.isHidden = true
        secondWindow = nil
    }
    
    fileprivate func alert(error: Error) {
        var message = ""
        switch error {
        case Chip8Error.invalidOpCode(let opCode):
            message = "Invalid op code: \(opCode)"
        case Chip8Error.invalidROMFile(let url):
            message = "Invalid ROM file: \(url)"
        case BuzzerError.error(let status):
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
        let bgColor = SettingsManager.instance.backgroundColor.floatTuple
        glClearColor(bgColor.0, bgColor.1, bgColor.2, bgColor.3)
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
