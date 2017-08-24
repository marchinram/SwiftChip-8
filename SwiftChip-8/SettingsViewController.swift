//
//  SettingsViewController.swift
//  SwiftChip-8
//
//  Created by Brian Rojas on 8/24/17.
//  Copyright © 2017 Brian Rojas. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    private var buzzer: Buzzer?
    
    private let notes = [Buzzer.Frequency.C4, Buzzer.Frequency.Db4, Buzzer.Frequency.D4, Buzzer.Frequency.Eb4,
                         Buzzer.Frequency.E4, Buzzer.Frequency.F4, Buzzer.Frequency.Gb4, Buzzer.Frequency.G4,
                         Buzzer.Frequency.Ab4, Buzzer.Frequency.A4, Buzzer.Frequency.Bb4, Buzzer.Frequency.B4]
    
    @IBOutlet weak var buzzerNoteLabel: UILabel!
    
    @IBOutlet weak var buzzerStepper: UIStepper!
    
    @IBOutlet weak var buzzerPreviewLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buzzerStepper.value = Double(notes.index(of: SettingsManager.instance.buzzerNote) ?? 1)
        buzzerNoteLabel.text = SettingsManager.instance.buzzerNote.description
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                if SettingsManager.instance.backgroundColor.isEqual(SettingsManager.orangeBackgroundColor) {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            } else if indexPath.row == 1 {
                if !SettingsManager.instance.backgroundColor.isEqual(SettingsManager.orangeBackgroundColor) {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                SettingsManager.instance.backgroundColor = SettingsManager.orangeBackgroundColor
                SettingsManager.instance.pixelColor = SettingsManager.yellowishPixelColor
            } else {
                SettingsManager.instance.backgroundColor = UIColor.black
                SettingsManager.instance.pixelColor = UIColor.white
            }
            tableView.reloadData()
        } else if indexPath.section == 1 && indexPath.row == 1 {
            togglePreview()
        }
    }
    
    @IBAction func didChangeBuzzerNote(_ sender: UIStepper) {
        let note = notes[Int(sender.value)]
        SettingsManager.instance.buzzerNote = note
        buzzerNoteLabel.text = SettingsManager.instance.buzzerNote.description
        
        if buzzer != nil {
            stopPreview()
            startPreview()
        }
    }
    
    @IBAction func didPressClose(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    private func togglePreview() {
        if buzzer == nil {
            startPreview()
        } else {
            stopPreview()
        }
    }
    
    private func startPreview() {
        do {
            buzzerPreviewLabel.text = "Stop Preview"
            buzzer = try Buzzer(frequency: SettingsManager.instance.buzzerNote)
            try buzzer?.sound()
        } catch {
            print(error)
        }
    }
    
    private func stopPreview() {
        buzzerPreviewLabel.text = "Start Preview"
        buzzer = nil
    }
    
}
