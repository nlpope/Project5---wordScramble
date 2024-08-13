//
//  ViewController.swift
//  Project5
//
//  Created by Noah Pope on 8/10/24.
//

import UIKit

class ViewController: UITableViewController {

    var allWords    = [String]()
    var usedWords   = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureArray()
        startGame()
    }
    
    
    func configureNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(promptForAnswer))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(restartGame))
    }
    
    
    func configureArray() {
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            print("test print startwordsURL: \(startWordsURL)")
            if let startWords = try? String(contentsOf: startWordsURL) {
                allWords = startWords.components(separatedBy: "\n")
            }
        }
        
        if allWords.isEmpty { allWords = ["silkworm"] }
    }
    
    
    func startGame() {
        title = allWords.randomElement()
        usedWords.removeAll(keepingCapacity: true)
        tableView.reloadData()
    }
    
    
    func presentError(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Ok", style: .default))
        present(ac, animated: true)
    }
    
    
    func submit(_ answer: String) {
        let lowerAnswer = answer.lowercased()
        let errorTitle: String
        let errorMessage: String
        
        guard isPossible(word: lowerAnswer) else {
            errorTitle      = "Word not possible"
            errorMessage    = "You can't spell that word from \(title!)."
            presentError(title: errorTitle, message: errorMessage)
            return
        }
        guard isOriginal(word: lowerAnswer) else {
            errorTitle      = "Word used already"
            errorMessage    = "Be more original."
            presentError(title: errorTitle, message: errorMessage)
            return
        }
        guard isReal(word: lowerAnswer) else {
            errorTitle      = "Word not recognised"
            errorMessage    = "You can't just make them up, you know. Also, answer must be three letters or more."
            presentError(title: errorTitle, message: errorMessage)
            return
        }
        
        usedWords.insert(lowerAnswer, at: 0)
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    
    func isOriginal(word: String) -> Bool { return !usedWords.contains(word) }

    
    func isPossible(word: String) -> Bool {
        guard var tempWord = title?.lowercased(), word != "" else { return false }
        
        for letter in word {
            if let position = tempWord.firstIndex(of: letter) { tempWord.remove(at: position) }
            else { return false }
        }
        
        return true
    }
    
    
    func isReal(word: String) -> Bool {
        guard word.utf16.count >= 3 else { return false }
        let checker         = UITextChecker()
        let range           = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        return misspelledRange.location == NSNotFound
    }
    
    
    @objc func promptForAnswer() {
        let ac = UIAlertController(title: "Enter answer", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak ac] _ in
            guard let self      = self else { return }
            guard let answer    = ac?.textFields?[0].text else { return }
            self.submit(answer)
        }
        
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    
    @objc func restartGame() { startGame() }
}


extension ViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usedWords.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell                = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        cell.textLabel?.text    = usedWords[indexPath.row]
        return cell
    }
}
