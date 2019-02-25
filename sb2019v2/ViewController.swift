//
//  ViewController.swift
//  sb2019v2
//
//  Created by Eric Hernandez on 2/2/19.
//  Copyright © 2019 Eric Hernandez. All rights reserved.
//

import UIKit
import AVKit
import MessageUI
import SwiftSoup
import CoreData

class ViewController: UIViewController,MFMessageComposeViewControllerDelegate {
    
    @IBOutlet weak var chkBtnSeg: UISegmentedControl!
    @IBOutlet weak var wordInfoSeg: UISegmentedControl!
    @IBOutlet weak var wordTxt: UITextField!
    @IBOutlet weak var progressLbl: UILabel!
    @IBOutlet weak var wordLbl: UILabel!
    
    var spellingWord = ""
    var builtUrl = ""
    var wordDefTxt = ""
    var wordTypeTxt = ""
    var wordPronounciationTxt = ""
    var wordSentenceTxt = ""
    var wordSoundFile = ""
    var wordSoundFileDir = ""
    var player: AVPlayer?
    let synthesizer = AVSpeechSynthesizer()
    
    var itemList = [String]()
    var itemArray = [Item]()
    var loadQuestions = WordBank()
    var questions = [Item]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var lastQIndex = 0
    var questionIndex = 0
    var markedQuestions = [Word]()
    var questionNumber: Int = 0
    var randomPick: Int = 0
    var correctAnswers: Int = 0
    var numberAttempts: Int = 0
    var totalNumberOfQuestions: Int = 0
    var markedQuestionsCount: Int = 0
    var markedWordForSMS = [""]
    
    let congratulateArray = ["Great Job", "Excellent", "Way to go", "Alright", "Right on", "Correct", "Well done", "Awesome"]
    let retryArray = ["Try again","Oooops"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //askQuestion()
        getWords()
    }
    //MARK: - Preload CoreData
//    func preloadCoreData(){
//        for word in loadQuestions.list{
//            let newItem = Item(context: self.context)
//            newItem.title = word.spellWord
//            self.itemArray.append(newItem)
//            self.saveItems()
//        }
//    }
//    func saveItems(){
//        do {
//            try context.save()
//        } catch {
//            print("Error saving context \(error)")
//        }
//    }
    func updateDate(){
    }
    func getWords(){
        
        let itemFetchRequest = NSFetchRequest<Item>(entityName: "Item")
        itemFetchRequest.fetchLimit = 10
        let allItems = try! context.fetch(itemFetchRequest)
        

        for item in allItems{
            itemList.append(item.title!)
            //print(item.title!)
        }
        //print(itemList)
        wordLbl.text = itemList.joined(separator: ", ")
        
    }
    func getCurrentShortDate() -> String {
        let todaysDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let DateInFormat = dateFormatter.string(from: todaysDate)
        
        return DateInFormat
    }
    func askQuestion() {
        wordTxt.text = ""
        self.wordTxt.becomeFirstResponder()

//        let numberOfQuestions = questions.list
//        totalNumberOfQuestions = numberOfQuestions.count
        totalNumberOfQuestions = questions.count
        
        if totalNumberOfQuestions == 0{
            
            let alert = UIAlertController(title: "Congratulations!", message: "You've finished, do you want to start over again?", preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Start Over", style: .default) { (handler) in
                self.sendSMS()
                self.startOver()
            }
            alert.addAction(restartAction)
            present(alert, animated: true, completion: nil)
        }
        else{
            lastQIndex = totalNumberOfQuestions - 1
            questionIndex = Int.random(in: 0...lastQIndex)
            //spellingWord = questions.list[questionIndex].spellWord
            //builtUrl = "https://www.merriam-webster.com/dictionary/\(spellingWord)"
            buildSearchUrl()
            let myURL = URL(string: builtUrl)
            let html = try! String(contentsOf: myURL!, encoding: .utf8)
            
            do {
                let doc: Document = try SwiftSoup.parseBodyFragment(html)
                let wordDef: Elements = try doc.getElementsByClass("dtText")
                let wordType = try doc.select("div.entry-header:nth-child(2) > div:nth-child(1) > span:nth-child(2) > a:nth-child(1)")
                let wordPronounciation = try doc.getElementsByClass("prs")
                let wordSentence = try doc.getElementsByClass("t has-aq")
                let wordWavFile = try doc.getElementsByClass("play-pron hw-play-pron")
                
                wordDefTxt = String(try wordDef.text().dropFirst())
                wordTypeTxt = try wordType.text()
                wordPronounciationTxt = try wordPronounciation.text()
                wordSentenceTxt = try wordSentence.text()
                wordSoundFile = try wordWavFile.attr("data-file")
                wordSoundFileDir = try wordWavFile.attr("data-dir")
                
            } catch Exception.Error(let type, let message) {
                print("Message: \(message)")
            } catch {print("error")}
            
            readMe(myText: "Definition is...... \(wordDefTxt).")
            enableAllBtn()
            chkBtnSeg.selectedSegmentIndex = -1
            wordInfoSeg.selectedSegmentIndex = -1
        }
    }
    func readMe( myText: String) {
        let utterance = AVSpeechUtterance(string: myText )
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }
    func buildSearchUrl(){
//        spellingWord = questions.list[questionIndex].spellWord
//        builtUrl = "https://www.merriam-webster.com/dictionary/\(spellingWord)"
        spellingWord = questions[questionIndex].title!
        builtUrl = "https://www.merriam-webster.com/dictionary/\(spellingWord)"
    }
    func goToMW(){
        if let mwUrl = URL(string: builtUrl){
            UIApplication.shared.open(mwUrl, options: [:])
        }
    }
    func getWordInfo(){
        let myURL = URL(string: builtUrl)
        let html = try! String(contentsOf: myURL!, encoding: .utf8)
        
        do {
            let doc: Document = try SwiftSoup.parseBodyFragment(html)
            let wordDef: Elements = try doc.getElementsByClass("dtText")
            let wordType = try doc.select("div.entry-header:nth-child(2) > div:nth-child(1) > span:nth-child(2) > a:nth-child(1)")
            let wordPronounciation = try doc.getElementsByClass("prs")
            let wordSentence = try doc.getElementsByClass("t has-aq")
            let wordWavFile = try doc.getElementsByClass("play-pron hw-play-pron")
            
            wordDefTxt = String(try wordDef.text().dropFirst())
            wordTypeTxt = try wordType.text()
            wordPronounciationTxt = try wordPronounciation.text()
            wordSentenceTxt = try wordSentence.text()
            wordSoundFile = try wordWavFile.attr("data-file")
            wordSoundFileDir = try wordWavFile.attr("data-dir")
            
        } catch Exception.Error(let type, let message) {
            print("Message: \(message)")
        } catch {print("error")}
    }
    func stopSpeaking(){
        synthesizer.stopSpeaking(at: .immediate)
    }
    func playsound(){
        let urlString = "https://media.merriam-webster.com/soundc11/\(wordSoundFileDir)/\(wordSoundFile).wav"
        guard let url = URL.init(string: urlString)
            else {return}
        let playerItem = AVPlayerItem.init(url: url)
        player = AVPlayer.init(playerItem: playerItem)
        player?.play()
    }
    func goToYouTube(){
        let YoutubeQuery =  spellingWord
        let escapedYoutubeQuery = YoutubeQuery.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let appURL = NSURL(string: "youtube://www.youtube.com/results?search_query=\(escapedYoutubeQuery!)")!
        let webURL = NSURL(string: "https://www.youtube.com/results?search_query=\(escapedYoutubeQuery!)")!
        let application = UIApplication.shared
        
        if application.canOpenURL(appURL as URL) {
            application.open(appURL as URL)
        } else {
            // if Youtube app is not installed, open URL inside Safari
            application.open(webURL as URL)
        }
    }
    func checkBtn(){
        //let spellWord = questions.list[questionIndex].spellWord
        let spellWord = spellingWord
        if spellWord == wordTxt.text?.lowercased() {
            randomPositiveFeedback()
            //questions.list.remove(at: questionIndex)
            questions.remove(at: questionIndex)
            //Wait 2 seconds before showing the next question
            let when = DispatchTime.now() + 2
            DispatchQueue.main.asyncAfter(deadline: when){
                //spell next word
                //self.questionNumber += 1
                self.askQuestion()
            }
            wordTxt.text = ""
            
            //increment number of correct answers
            correctAnswers += 1
            numberAttempts += 1
            updateProgress()
        } else {
            randomTryAgain()
            numberAttempts += 1
            updateProgress()
            trackMarkedQuestions()
        }
    }
    func randomPositiveFeedback(){
        randomPick = Int(arc4random_uniform(8))
        readMe(myText: congratulateArray[randomPick])
    }
    func randomTryAgain(){
        randomPick = Int(arc4random_uniform(2))
        readMe(myText: retryArray[randomPick])
        chkBtnSeg.selectedSegmentIndex = -1
    }
    func updateProgress(){
        progressLbl.text = "Correct/Attempt: \(correctAnswers) / \(numberAttempts)"
    }
    func repeatBtn() {
        //readMe(myText: questions.list[questionIndex].spellWord)
        readMe(myText: spellingWord)
    }
    func showWord(){
        //wordTxt.text = questions.list[questionIndex].spellWord.uppercased()
        wordTxt.text = spellingWord.uppercased()
        numberAttempts += 1
        updateProgress()
        chkBtnSeg.setEnabled(false, forSegmentAt: 0)
    }
    func startOver(){
        correctAnswers = 0
        numberAttempts = 0
        updateProgress()
        //questions = WordBank()
        questions = [Item]()
        askQuestion()
        
    }
    func trackMarkedQuestions(){
        //let trackedWord = questions.list[questionIndex].spellWord
        let trackedWord = spellingWord
        markedWordForSMS.append(trackedWord)
        
        markedQuestions.append(Word(word: trackedWord))
        markedQuestionsCount += 1
    }
    func sendSMS(){
        let combinedMarkedWords = markedWordForSMS.joined(separator: ", ")
        let messageVC = MFMessageComposeViewController()
        
        messageVC.body = combinedMarkedWords;
        messageVC.recipients = ["469-910-6366"]
        messageVC.messageComposeDelegate = self
        
        self.present(messageVC, animated: false, completion: nil)
    }
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch (result) {
        case .cancelled:
            print("Message was cancelled")
            dismiss(animated: true, completion: nil)
        case .failed:
            print("Message failed")
            dismiss(animated: true, completion: nil)
        case .sent:
            print("Message was sent")
            dismiss(animated: true, completion: nil)
        default:
            break
        }
    }
    @IBAction func checkBtnSeg(_ sender: Any) {
        let chkBtnSegIndex = chkBtnSeg.selectedSegmentIndex
        switch chkBtnSegIndex {
        case 0:
            checkBtn()
        case 1:
            repeatBtn()
            chkBtnSeg.selectedSegmentIndex = -1
        case 2:
            showWord()
            trackMarkedQuestions()
            chkBtnSeg.setEnabled(false, forSegmentAt: 0)
        case 3:
            //questions.list.remove(at: questionIndex)
            questions.remove(at: questionIndex)
            askQuestion()
        default:
            wordTxt.text = "There's a problem!"
    }
}
    func enableAllBtn(){
        chkBtnSeg.setEnabled(true, forSegmentAt: 0)
        chkBtnSeg.setEnabled(true, forSegmentAt: 1)
        chkBtnSeg.setEnabled(true, forSegmentAt: 2)
        chkBtnSeg.setEnabled(true, forSegmentAt: 3)
        wordInfoSeg.setEnabled(true, forSegmentAt: 0)
        wordInfoSeg.setEnabled(true, forSegmentAt: 1)
        wordInfoSeg.setEnabled(true, forSegmentAt: 2)
        wordInfoSeg.setEnabled(true, forSegmentAt: 3)
        wordInfoSeg.setEnabled(true, forSegmentAt: 4)
        wordInfoSeg.setEnabled(true, forSegmentAt: 5)
    }
    @IBAction func wordInfoSeg(_ sender: Any) {
        buildSearchUrl()
        getWordInfo()
        
        let wordInfoIndex = wordInfoSeg.selectedSegmentIndex
        switch wordInfoIndex {
        case 0:
            goToMW()
            chkBtnSeg.setEnabled(false, forSegmentAt: 0)
        case 1:
            readMe(myText: wordDefTxt)
        case 2:
            stopSpeaking()
        case 3:
            wordTxt.text = wordPronounciationTxt
        case 4:
            playsound()
        case 5:
            goToYouTube()
            chkBtnSeg.setEnabled(false, forSegmentAt: 0)
        default:
            wordTxt.text = "There's an Error!"
        }
    }
    
}

