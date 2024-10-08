//
//  ViewController.swift
//  Project5 - word scramble anagram game
//
//  Created by Noah Pope on 8/10/24.
//

import UIKit

class ViewController: UITableViewController {
    
    enum Keys {
        static let currentWord  = "currentWord"
        static let usedWords    = "usedWords"
        static let loadFromSave = "loadFromSave"
    }

    var allWords    = [String]()
    var usedWords   = [String]()
    var loadGame    = false {
        didSet { encodeLoadStatus() }
    }
    var currentWord = "" {
        didSet { loadGame = true }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureArray()
        startGame()
    }
    
    
    func startGame() {
        decodeLoadStatus()
        if loadGame {
            loadCurrentWordAndAnswers()
            return
        }
        title       = allWords.randomElement()
        usedWords.removeAll(keepingCapacity: true)
        tableView.reloadData()
        currentWord = title!
        saveCurrentWordAndAnswers()
        //savecurrentwordandanswers()?
        presentInstructions()
    }
    
    
    @objc func restartGame() {
        loadGame = false
        startGame()
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
        saveCurrentWordAndAnswers()
    }
    
    
    func encodeLoadStatus() {
        let jsonEncoder             = JSONEncoder()
        if let encodedLoadStatus    = try? jsonEncoder.encode(loadGame) {
            let defaults            = UserDefaults.standard
            defaults.set(encodedLoadStatus, forKey: Keys.loadFromSave)
            print("encoded load status = \(loadGame)")
        } else {
            print("unable to encode load status")
        }
    }
    
    
    func decodeLoadStatus() {
        let defaults                = UserDefaults.standard
        
        if let encodedLoadStatus    = defaults.object(forKey: Keys.loadFromSave) as? Data {
            let jsonDecoder         = JSONDecoder()
            do {
                loadGame            = try jsonDecoder.decode(Bool.self, from: encodedLoadStatus)
                print("decoded load status = \(loadGame)")
            } catch {
                print("failed to load current word")
            }
        }
    }
    
    
    func saveCurrentWordAndAnswers() {
        let jsonEncoder                 = JSONEncoder()
        if let encodedCurrentWord       = try? jsonEncoder.encode(currentWord) {
            let defaults                = UserDefaults.standard
            defaults.set(encodedCurrentWord, forKey: Keys.currentWord)
            print("savedCurrentWord = \(currentWord)")
        } else {
            print("unable to save current word")
        }
        
        if let encodedUsedWords         = try? jsonEncoder.encode(usedWords) {
            let defaults                = UserDefaults.standard
            defaults.set(encodedUsedWords, forKey: Keys.usedWords)
            print("savedusedwords = \(encodedUsedWords)")
            print("savedusedwords = \(usedWords)")
        } else {
            print("unable to save usedwords")
        }
    }
    
    
    func loadCurrentWordAndAnswers() {
        let defaults                = UserDefaults.standard
        
        if let encodedCurrentWord   = defaults.object(forKey: Keys.currentWord) as? Data {
            let jsonDecoder         = JSONDecoder()
            do {
                #warning("didset is causing a save of an empty usedwords array")
                title               = try jsonDecoder.decode(String.self, from: encodedCurrentWord)
                currentWord         = title!
                print("loaded current word = \(currentWord)")
            } catch {
                print("failed to load current word")
            }
        }
        
        if let encodedUsedWords     = defaults.object(forKey: Keys.usedWords) as? Data {
            let jsonDecoder         = JSONDecoder()
            do {
                usedWords           = try jsonDecoder.decode([String].self, from: encodedUsedWords)
                print("loaded used words = \(usedWords)")
            } catch {
                print("failed to load used word")
            }
        }
    }
    
    
    // MARK: END OF PROBLEM CHILD
    func configureNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(promptForAnswer))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(restartGame))
    }
    
    
    func configureArray() {
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL) {
                allWords = startWords.components(separatedBy: "\n")
            }
        }
        
        if allWords.isEmpty { allWords = ["silkworm"] }
    }
    
    
    func presentInstructions() {
        let message = "This is an anagram game. Try and spell as many words as you can using the letters from the word above, used words will be listed as you progress."
        let ac      = UIAlertController(title: "Instructions", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Ok", style: .default))
        present(ac, animated: true)
    }
    
    
    func presentError(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Ok", style: .default))
        present(ac, animated: true)
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
