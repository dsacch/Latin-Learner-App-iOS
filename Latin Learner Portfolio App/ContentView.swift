//
//  ContentView.swift
//  Latin Learner Portfolio App
//
//  Created by Oliver Walsh on 12/2/22.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

let salutations = ["Hey there", "Welcome", "What's up", "Hello"]
let chosenSalutation = salutations.randomElement()!

struct ContentView: View {
    @EnvironmentObject var vm: UserAuthModel
    
    var body: some View {
        if(vm.isLoggedIn){
            VStack{
                topbar()
                homePageContent()
            }.ignoresSafeArea()
        } else {
            loginScreen()
        }
    }
}

struct homePageContent: View {
    @EnvironmentObject var vm: UserAuthModel
    @ObservedObject var d = download()
    @State var data: [String] = []
    
    var body: some View {
        ScrollView(showsIndicators: false){
            VStack{
                Spacer()
                VStack{
                    Spacer().frame(height: 60)
                    Button(action: {
                        d.retrieveImage { data in
//                            print(data) // prints a list of all the URLs stored in your FireBase Store document
                            self.data = data
                        }
                    }){
                        Text("Download")
                    }
                    ForEach(data, id: \.self) {
                        examplePost(url: $0)
                    }
                }
                HStack{
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color.gray)
                    Spacer().frame(width: 15)
                    Text("You've reached the end of your feed").mediumText()
                        .foregroundColor(Color.gray)
                    Spacer()
                }
                Spacer().frame(minHeight: 150)
                
            }
        }
    }
}

struct examplePost: View {
    @State var imageURL: String
    init(url: String) {
        self.imageURL = url
    }
    var body: some View {
        AsyncImage(url: URL(string: "\(imageURL)")) { phase in
            if let image = phase.image {
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .frame(width: 360, height: 270)
        .background(Color.gray)
        HStack{
            Text("Skill").mediumText()
            Spacer()
            Text("Date").mediumText()
        }.frame(width: 360)
        Spacer().frame(height: 60)
    }
}
