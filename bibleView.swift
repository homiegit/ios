//
//  BibleView.swift
//  homie-ios
//
//  Created by Diego Lares on 9/8/23.
//

import SwiftUI

struct SearchResults: Codable, Hashable {
    let version: String
    let verseId: Int
    let bookName: String
    let bookNumber: Int
    let chapter: Int
    let verse: Int
    let text: String

}

struct BibleView: View {
    @EnvironmentObject var viewRouter: ViewRouter
    @EnvironmentObject var viewModel: ContentViewModel

    @State var searchTerm: String = ""
    @State var searchResults: [SearchResults] = []
    @State var showResults: Bool = false
    
    @State var book: String = "Genesis"
    @State var chapter: Int = 1
    @State var version: String = "ASV"
    
    @State var chapterContent: [String] = []
    
    @State var showBooks: Bool = false
    @State var showChapters: Bool = false
    @State var showVersions: Bool = false

    @State var setAnchor: Int = 0
    
    var allBooks: [String: Int] = [
        "Genesis": 50,
        "Exodus": 40,
        "Leviticus": 27,
        "Numbers": 36,
        "Deuteronomy": 34,
        "Joshua": 24,
        "Judges": 21,
        "Ruth": 4,
        "1 Samuel": 31,
        "2 Samuel": 24,
        "1 Kings": 22,
        "2 Kings": 25,
        "1 Chronicles": 29,
        "2 Chronicles": 36,
        "Ezra": 10,
        "Nehemiah": 13,
        "Esther": 10,
        "Job": 42,
        "Psalms": 150,
        "Proverbs": 31,
        "Ecclesiastes": 12,
        "Song of Solomon": 8,
        "Isaiah": 66,
        "Jeremiah": 52,
        "Lamentations": 5,
        "Ezekiel": 48,
        "Daniel": 12,
        "Hosea": 14,
        "Joel": 3,
        "Amos": 9,
        "Obadiah": 1,
        "Jonah": 4,
        "Micah": 7,
        "Nahum": 3,
        "Habakkuk": 3,
        "Zephaniah": 3,
        "Haggai": 2,
        "Zechariah": 14,
        "Malachi": 4,
        "Matthew": 28,
        "Mark": 16,
        "Luke": 24,
        "John": 21,
        "Acts": 28,
        "Romans": 16,
        "1 Corinthians": 16,
        "2 Corinthians": 13,
        "Galatians": 6,
        "Ephesians": 6,
        "Philippians": 4,
        "Colossians": 4,
        "1 Thessalonians": 5,
        "2 Thessalonians": 3,
        "1 Timothy": 6,
        "2 Timothy": 4,
        "Titus": 3,
        "Philemon": 1,
        "Hebrews": 13,
        "James": 5,
        "1 Peter": 5,
        "2 Peter": 3,
        "1 John": 5,
        "2 John": 1,
        "3 John": 1,
        "Jude": 1,
        "Revelation": 22
    ]
    
    var allBookNames: [String] = [
        "Genesis",
        "Exodus",
        "Leviticus",
        "Numbers",
        "Deuteronomy",
        "Joshua",
        "Judges",
        "Ruth",
        "1 Samuel",
        "2 Samuel",
        "1 Kings",
        "2 Kings",
        "1 Chronicles",
        "2 Chronicles",
        "Ezra",
        "Nehemiah",
        "Esther",
        "Job",
        "Psalms",
        "Proverbs",
        "Ecclesiastes",
        "Song of Solomon",
        "Isaiah",
        "Jeremiah",
        "Lamentations",
        "Ezekiel",
        "Daniel",
        "Hosea",
        "Joel",
        "Amos",
        "Obadiah",
        "Jonah",
        "Micah",
        "Nahum",
        "Habakkuk",
        "Zephaniah",
        "Haggai",
        "Zechariah",
        "Malachi",
        "Matthew",
        "Mark",
        "Luke",
        "John",
        "Acts",
        "Romans",
        "1 Corinthians",
        "2 Corinthians",
        "Galatians",
        "Ephesians",
        "Philippians",
        "Colossians",
        "1 Thessalonians",
        "2 Thessalonians",
        "1 Timothy",
        "2 Timothy",
        "Titus",
        "Philemon",
        "Hebrews",
        "James",
        "1 Peter",
        "2 Peter",
        "1 John",
        "2 John",
        "3 John",
        "Jude",
        "Revelation"
    ]
    
    var allVersions: [String] = ["ASV", "KJV", "WEB"]

    var body: some View {
        Spacer()
        VStack {
            
            Spacer()
            TextField("", text: $searchTerm)
                .font(.system(size: 15))
                .padding(5)
                .foregroundColor(.black)
                .frame(width: screenWidth / 1.2, height: screenHeight / 30)
                .border(Color.black, width: 1)
                .onTapGesture {
                    showResults = true
                }

            if showResults {
                VStack{
                    ScrollView{
                        ForEach(searchResults, id: \.self){result in
                            Button(action: {
                                book = result.bookName
                                chapter = result.chapter
                                version = result.version
                                getBible(book: result.bookName, chapter: result.chapter, version: result.version)
                                showResults = false
                                setAnchor = 1
                                if let index = chapterContent.firstIndex(where: { $0.contains("[\(result.verse)]") }) {
                                      setAnchor = index
                                  }
                            }) {
                                VStack{
                                    Text("[\(result.version)] \(result.bookName) \(result.chapter) : \(result.verse)")
                                        .font(.system(size: 20))
                                        .padding(0)
                                        .foregroundColor(.white)
                                    Text("\(result.text)")
                                        .font(.system(size: 20))
                                        .padding(0)
                                        .foregroundColor(.white)
                                }
                            }
                            .border(Color.white, width: 1)
                        }
                    }
                }
                .frame(width: screenWidth / 1.2, height: screenHeight / 3)
                .background(Color.black)
                .border(Color.white, width: 2)
            }
            HStack {
                Button(action: {
                    if chapter != 1 {
                        chapter -= 1
                        getBible(book: book, chapter: chapter, version: version)
                    } else {

                    }
                    if showBooks {
                        showBooks.toggle()
                    }
                    if showChapters {
                        showChapters.toggle()
                    }
                    if showVersions {
                        showVersions.toggle()
                    }

                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 25))
                        .foregroundColor(.black)
                }
                Spacer()
                
                Button(action: {
                    if showChapters{
                        showChapters.toggle()
                    }
                    if showVersions {
                        showVersions.toggle()
                    }
                    showBooks.toggle()
                }) {
                    Text("\(book)")
                        .font(.system(size: 30))
                        .foregroundColor(.black)
                }
                Button(action: {
                    if showVersions {
                        showVersions.toggle()
                    }
                    if showBooks {
                        showBooks.toggle()
                    }
                    showChapters.toggle()
                }) {
                    Text("\(chapter)")
                        .font(.system(size: 30))
                        .foregroundColor(.black)
                }
                Button(action: {
                    if showChapters{
                        showChapters.toggle()
                    }
                    if showBooks {
                        showBooks.toggle()
                    }
                    showVersions.toggle()
                }) {
                    Text("\(version)")
                        .font(.system(size: 30))
                        .foregroundColor(.black)
                }
                
                
                Spacer()
                
                Button(action: {
                    let numberOfChapters = allBooks[book]
                    
                    // Find the next book with a matching chapter
                    if chapter == numberOfChapters {
                        print("allBookNames:", allBookNames)

                        if let currentIndex = allBookNames.firstIndex(of: book), currentIndex < allBookNames.count - 1 {
                            let nextBook = allBookNames[currentIndex + 1]
                            print("nextBook:", nextBook)
                            book = nextBook
                            chapter = 1
                            getBible(book: book, chapter: chapter, version: version)
                        }
                    } else {
                        chapter += 1
                        getBible(book: book, chapter: chapter, version: version)
                    }
                    
                    if showBooks {
                        showBooks.toggle()
                    }
                    if showChapters {
                        showChapters.toggle()
                    }
                    if showVersions {
                        showVersions.toggle()
                    }
                }) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 25))
                        .foregroundColor(.black)
                }

            }
            if showBooks {
                Text("Book")
                    .font(.system(size: 25))
                    .foregroundColor(.black)
                    .padding(.bottom, -10)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 2) {
                        ForEach(allBookNames, id: \.self) { bookName in
                            Button(action: {
                                self.book = bookName
                                self.showBooks = false
                                self.getBible(book: book, chapter: chapter, version: version)
                            }) {
                                Text("\(bookName)")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(5)
                            }
                        }
                    }
                }
                .frame(width: screenWidth / 1.1, height: screenHeight / 4)
                .background(Color.black)
                .border(Color.brown, width: 2)
            }

            if showChapters {
                Text("Chapter")
                    .font(.system(size: 25))
                    .foregroundColor(.black)
                    .padding(.bottom, -10)

                ScrollView {
                    ForEach(1..<(allBooks[book] ?? 0) + 1, id: \.self) { chapterNumber in
                        Button(action: {
                            self.chapter = chapterNumber
                            self.showChapters = false
                            self.getBible(book: book, chapter: chapter, version: version)
                        }) {
                            Text("\(chapterNumber)")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(3)
                        }
                    }
                
                }
                .frame(width: screenWidth / 5.5, height: screenHeight / 4)
                .background(Color.black)
                .border(Color.brown, width: 2)
            }
            if showVersions {
                Text("Version")
                    .font(.system(size: 25))
                    .foregroundColor(.black)
                    .padding(.bottom, -10)
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 2) {
                        
                        ForEach(allVersions, id: \.self) {version in
                            Button(action: {
                                self.version = version
                                self.showVersions = false
                                self.getBible(book: book, chapter: chapter, version: version)
                                
                            }) {
                                Text("\(version)")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(5)
                            }
                            
                        }
                    }
                }
                .frame(width: screenWidth / 3, height: screenHeight / 4)
                .background(Color.black)
                .border(Color.brown, width: 2)

            }
            ScrollViewReader{proxy in
                ScrollView{
                    ForEach(chapterContent.indices, id: \.self){verse in
                        Text("\(chapterContent[verse])")
                            .font(.system(size: 25))
                            .foregroundColor(.black)
                            .padding(5)
                            .lineLimit(nil)
                            .id(verse)
                            .frame(maxWidth: screenWidth / 1.2 , alignment: .leading)
                            //.padding(5)
                    }
                }
                .onChange(of: setAnchor) { newAnchor in
                    // Scroll to the verse with the matching text
                    withAnimation {
                        proxy.scrollTo(newAnchor, anchor: .top)
                    }
                }
            }
        }
        .frame(width: screenWidth, height: screenHeight / 1.09)
        .navigationBarBackButtonHidden()
        .background(Color.purple)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded {gesture in
                    if gesture.translation.width > 0 {
                        DispatchQueue.main.async {
                            viewRouter.popToLast()
                        }
                }
            }
        )
        .onAppear{
            
            if let bibleSource = viewModel.bibleSource {
                book = bibleSource.book
                chapter = bibleSource.chapter
                getBible(book: bibleSource.book, chapter: bibleSource.chapter, version: viewModel.preferredVersion)
            } else {
                getBible(book: book, chapter: chapter, version: version)
            }
        }
        .onChange(of: searchTerm) {term in
            searchBible(searchTerm: term)
        }
        .onChange(of: book){bookname in
            if let numberOfChapterInCurrentBook = allBooks[bookname] {
                if numberOfChapterInCurrentBook < chapter {
                    chapter = 1
                    getBible(book: book, chapter: chapter, version: version)
                }
            }
        }
        .onChange(of: chapter){ _ in
            setAnchor = -1
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false){timer in
                setAnchor = 0
            }

        }
    }
    
    public func getBible(book: String, chapter: Int, version: String) {
        // Assuming your server URL is provided as an environment variable named "serverIpUrl"
        guard let serverIpUrlString = ProcessInfo.processInfo.environment["serverIpUrl"],
              let serverUrl = URL(string: serverIpUrlString) else {
            print("Error: Invalid server URL")
            return
        }
        
        // Construct the URL for the GET request
        let getBibleEndpoint = serverUrl.appendingPathComponent("/api/getBible")
        
        // Create query parameters
        let queryItems = [
            URLQueryItem(name: "book", value: book),
            URLQueryItem(name: "chapter", value: String(chapter)),
            URLQueryItem(name: "version", value: version)
        ]
        
        var urlComponents = URLComponents(url: getBibleEndpoint, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = queryItems
        
        // Create the URLRequest
        guard let requestUrl = urlComponents?.url else {
            print("Error: Unable to create request URL")
            return
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        
        // Create a URLSession task to send the GET request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            if let data = data {
                if let jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [String] {
                    chapterContent = jsonArray
                }
            }
        }
        
        // Start the URLSession task
        task.resume()
    }
    
    func searchBible(searchTerm: String) {
        // Assuming your server URL is provided as an environment variable named "serverIpUrl"
        guard let serverIpUrlString = ProcessInfo.processInfo.environment["serverIpUrl"],
              let serverUrl = URL(string: serverIpUrlString) else {
            print("Error: Invalid server URL")
            return
        }
        
        // Construct the URL for the GET request
        let searchBibleEndpoint = serverUrl.appendingPathComponent("/api/searchBible")
        
        //let searchTermArray = searchTerm.components(separatedBy: " ")

        // Create query parameters
//        let queryItems = searchTermArray.map { term in
//            URLQueryItem(name: "searchTerm", value: term)
//        }
        
        let queryItems = [
            URLQueryItem(name: "searchTerm", value: searchTerm)
        ]
        var urlComponents = URLComponents(url: searchBibleEndpoint, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = queryItems
        
        // Create the URLRequest
        guard let requestUrl = urlComponents?.url else {
            print("Error: Unable to create request URL")
            return
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        
        // Create a URLSession task to send the GET request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            guard let data = data else {
                     print("Error: No data received")
                     return
                 }
                 
                 do {
                     // Decode the JSON response into an array of SearchResults objects
                     let decoder = JSONDecoder()
                     let searchResultsArray = try decoder.decode([SearchResults].self, from: data)
                     searchResults = searchResultsArray
                     // Here, you have the 'searchResultsArray' containing your search results
                     print("searchResultsArray:", searchResultsArray)
                     
                     // Now you can further process the search results as needed
                 } catch {
                     print("Error decoding JSON: \(error)")
                 }
        }
        
        // Start the URLSession task
        task.resume()
    }
}

struct BibleView_Previews: PreviewProvider {
    static var previews: some View {
        BibleView()
    }
}
