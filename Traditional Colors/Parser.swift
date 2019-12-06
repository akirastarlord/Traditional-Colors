//
//  Parser.swift
//  WebParser
//
//  Created by yy的mac on 2019/11/21.
//  Copyright © 2019 yy的mac. All rights reserved.
//

import Foundation
import Kanna
import SwiftSoup

protocol ParserDelegate: class {
    func didFinishCollectingColors(_ colorList: [Color])
}

protocol StoryReaderDelegate: class {
    func didFinishReadingStories()
}

/* delegate for comprehensive web parsing
 and writing to local JSON file */
protocol ReaderManagerDelegate: class {
    func didFinishToplevelReading(_ p: Parser)
    func didFinishComprehensiveReading(_ p: Parser)
}

class Parser {
    private var urlString: String
    var url: URL
    // actual html page cached
    var html: String = ""
    
    var colorsCollected = [Color]()
    
    // delegate property
    weak var delegate: ParserDelegate?
    
    weak var detailPageParserDelegate: StoryReaderDelegate?
    
    weak var parserManager: ReaderManagerDelegate?
    
    var articlesRead: Int = 0
    
    init(url: String) {
        self.urlString = url
        self.url = URL(string: urlString)!
    }
    
    func setURL(_ uri: String) {
        urlString = uri;
        url = URL(string: urlString)!
    }
    
    func parse() {
        print("start parsing webpage")
        let task = URLSession.shared.dataTask(with: url) { (data, reponse, error) in
            guard let data = data, error == nil else {
                print("Request of visiting page failed")
                return
            }
        }
        task.resume()
        print("finished parsing webpage")
    }
    
    func doKanna() {
        print("start Kanna web parsing")
        if let doc: HTMLDocument = try? HTML(url: url, encoding: .utf8) {
            
            /* CSS Selector selection */
            let bodyNode = doc.body
            if let colors = bodyNode?.css("#gojuon") {
                print("Num of children nodes is \(colors.count)")
                if colors.count >= 1 {
                    let c = colors[0].at_css("p")
                    print(c?.innerHTML)
                }
            }
            //print(bodyNode?.content)
            
            /* XPath selection */
            //if let nodes = bodyNode?.xpath("//div/main/article/div/@id=gojuon") {
                //print(nodes.count)
                //print(nodes.self)
                //print(nodes[4].self)
                //print(nodes[4].innerHTML!)
                
                //print(nodes[4].at_css("[id=gojuon]"))
        }
        print("Kanna ends")
    }
    
    func doSwiftSoup() {
        let task = URLSession.shared.dataTask(with: url) { (data, reponse, error) in
            guard let data = data, error == nil else {
                print("Request of visiting page failed")
                return
            }
            self.html = String(data: data, encoding: .utf8) ?? ""

            print("start SwiftSoup web parsing")
            //print(self.html == "")
            if self.html != "" {
                //print(self.html)
            }
            do {
                let doc: Document = try SwiftSoup.parse(self.html)
                let gojuon = try doc.getElementById("gojuon")
                //print(gojuon!)
                let colors: [Element] = try gojuon!.getElementsByTag("p").array()
                
                //MARK: - Note section
                /* NOTE: colors[0] is 藍色 (ai-iro),
                   a color element with structure
                 <p>
                   <a href="https://irocore.com/ai-iro/" style="background:#105779;color:#ffffff;">藍色
                     <span>Ai-iro</span>
                   </a>
                   <span>あいいろ</span>
                 </p>
                */
                //print(colors[0])
                /* NOTE: color[0].child(0) is
                 <a href="https://irocore.com/ai-iro/" style="background:#105779;color:#ffffff;">藍色
                   <span>Ai-iro</span>
                 </a>
                */
                // print(colors[0].child(0))
                /* NOTE: color[0].child(1) is
                 <span>あいいろ</span>
                */
                // print(colors[0].child(1))
                
                /*
                let kanjiName = colors[0].child(0).ownText() // 藍色
                print(kanjiName)
                let roma = try colors[0].child(0).child(0).text() // Ai-iro
                let link = try colors[0].child(0).attr("href") // https://irocore.com/ai-iro/
                let hiragana = try colors[0].child(1).text() // あいいろ
                let colorComb = try colors[0].child(0).attr("style")
                let colorStartIndex = colorComb.firstIndex(of: "#") ?? colorComb.startIndex
                let colorEndIndex = colorComb.firstIndex(of: ";") ?? colorComb.endIndex
                // save Substring to String
                let realColor = String(colorComb[colorStartIndex..<colorEndIndex])
                print(realColor)
                */
                
                // MARK: - End of Note section
                
                for c in colors {
                    if !c.hasClass("gotop") {
                        let kanjiName = c.child(0).ownText()
                        let colorComb = try c.child(0).attr("style")
                        let colorStartIndex = colorComb.firstIndex(of: "#") ?? colorComb.startIndex
                        let colorEndIndex = colorComb.firstIndex(of: ";") ?? colorComb.endIndex
                        let realColor = String(colorComb[colorStartIndex..<colorEndIndex])
                        let hiragana = try c.child(1).text()
                        let roma = try c.child(0).child(0).text()
                        let newColor = Color(name: kanjiName, colorCode: realColor, hiragana: hiragana, romanji: roma)
                        newColor.link = try c.child(0).attr("href")
                        self.colorsCollected.append(newColor)
                    }
                }
                /* 477 colors in total (is being updated) */
                //print("there are \(colors.count) number of lines under division \"gojuon\"") // 486
                //print("there are \(unmatchCount) lines of unmatched lines") // 10
                print("Collected \(self.colorsCollected.count) colors from \(self.urlString).")
            } catch Exception.Error(let type, let message) {
                print("Encounter error of type \(type) in parsing HTML")
                print(message)
            } catch {
                print("Unidentified error in SwiftSoup parsing")
            }
            print("SwiftSoup ends")
            self.delegate?.didFinishCollectingColors(self.colorsCollected)
            self.parserManager?.didFinishToplevelReading(self)
            
        }
        task.resume()
    }

    func readDetailPage(_ c: Color) {
        /* check it's a valid detail page */
        if let link = c.link {
            setURL(link)
        }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, error == nil else {
                print("Request of vising detail page failed")
                return
            }
            self.html = String(data: data, encoding: .utf8) ?? ""
            print("SwiftSoup starts reading detail page for \(c.name)")
            if self.html == "" { return }
            do {
                let doc: Document = try SwiftSoup.parse(self.html)
                let article = try doc.getElementById("content")?.getElementsByTag("article")
                
                // find RGB and CMYK
                // regex: R:(\d+)\ G:(\d+)\ B:(\d+)
                let rgbText = try article?[0].getElementsByClass("rgb").text()
                let cmykText = try article?[0].getElementsByClass("cmyk").text()
                if let rgbText = rgbText, let cmykText = cmykText {
                    let cv: ColorValue = String.extractColorValue(rgbString: rgbText, cmykString: cmykText)
                    c.colorValue = cv
                }
                
                let storyHeader = try article?[0].getElementsByTag("h3")[0]
                var paragraph: String = ""
                var p = try storyHeader?.nextElementSibling()
                /* while let combination */
                while let actualP = p {
                    if actualP.tagName() == "p", try actualP.className() != "dotted" {
                        try paragraph.append(actualP.text() + "\n\n")
                        p = try p?.nextElementSibling()
                    }
                    else { break }
                }
                paragraph = paragraph.endingNewLinesRemoved()
                //print(paragraph)
                c.story = paragraph
              
                self.articlesRead += 1
                
            } catch Exception.Error(let type, let message) {
                print("Encounter error of type \(type) in parsing HTML")
                print(message)
            } catch {
                print("Unidentified error in SwiftSoup parsing")
            }
            
            print("SwiftSoup finished reading detail page for \(c.name)")
            self.detailPageParserDelegate?.didFinishReadingStories()
            
            if self.articlesRead == self.colorsCollected.count {
                self.parserManager?.didFinishComprehensiveReading(self)
            }
        }
        task.resume()
    }
    
    func readComprehensive() {
        print("Starts comprehensive reading")
        articlesRead = 0
        for c in colorsCollected {
            readDetailPage(c)
        }
    }
    
    
    // MARK: - Writing to JSON file (usually deactivated)
    func writeToJsonFile() {
        /* document directory for this app on this device */
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "Colors.json"
        let fullPath = path.appendingPathComponent(fileName)
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self.colorsCollected)
            let jsonStr = String(data: data, encoding: .utf8)
            try jsonStr?.write(to: fullPath, atomically: true, encoding: .utf8)
        } catch is EncodingError {
            print("encoding error in encoding JSON")
        } catch {
            print("unidentified exception in writing data to file")
        }
        print("Successfully written to \(fullPath)")
    }
    
    // MARK: - Writing colors in simple forms (just name and colorCode) to txt (usually deactivated)
    /*
    func writecolorsInSimpleFormToTxt() {
        print("starts reading colors in simple form")
        let task = URLSession.shared.dataTask(with: url) { (data, reponse, error) in
            guard let data = data, error == nil else {
                print("Request of visiting page failed")
                return
            }
            self.html = String(data: data, encoding: .utf8) ?? ""

            if self.html != "" {
            }
            do {
                let doc: Document = try SwiftSoup.parse(self.html)
                let gojuon = try doc.getElementById("gojuon")
                //print(gojuon!)
                let colors: [Element] = try gojuon!.getElementsByTag("p").array()
                for c in colors {
                    if !c.hasClass("gotop") {
                        let kanjiName = c.child(0).ownText()
                        let colorComb = try c.child(0).attr("style")
                        let colorStartIndex = colorComb.firstIndex(of: "#") ?? colorComb.startIndex
                        let colorEndIndex = colorComb.firstIndex(of: ";") ?? colorComb.endIndex
                        let realColor = String(colorComb[colorStartIndex..<colorEndIndex])
                        let newColor = Color(name: kanjiName, colorCode: realColor)
                        print("\(newColor.name) \(newColor.colorCode)")
                    }
                }
            } catch Exception.Error(_, let message) {
                print(message)
            } catch {
            }
            print("Simple Reading ends")
        }
        task.resume()
    }
     */
    
}



/**
class ParserManager: UIViewController, ComprehensiveReaderDelegate {
    
    //var parser: Parser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func didFinishPreComprehensiveReading(_ p: Parser) {
        p.readComprehensive()
    }
    
    func didFinishComprehensiveReading() {
        print("Finally, has finished")
    }
}
*/
