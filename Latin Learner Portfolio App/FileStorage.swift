//struct example: View {
//    var body: some View {
//
//    }
//}

//
//  FileStorage.swift
//  Latin Learner Portfolio App
//
//  Created by Domenic Sacchetti on 12/6/22.
//
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

class FirebaseManager: NSObject {
    
    let auth: Auth
    let storage: Storage
    let firestore: Firestore
    
    static let shared = FirebaseManager()
    
    override init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        self.firestore = Firestore.firestore()
        
        super.init()
    }
    
}

class upload: ObservableObject {
    @Published var awaitfileUpload = false
    @Published var uploadedSuccessfully = false
    @Published var uploadErrMessage = "EXAMPLE ERROR MESSAGE"
    
    @Published var uploadInProgress = false
    
    @Published var tag = ""
    
    func reset() {
        self.awaitfileUpload = false
        self.uploadedSuccessfully = false
        self.uploadErrMessage = "EXAMPLE ERROR MESSAGE"
    }
    
    func persistImageToStorage(image: UIImage?, tag: String, name: String) {
        self.uploadInProgress = true
        let imageToUpload = image
        
        let words = name.components(separatedBy: " ")
        var formattedName = ""
        for word in words {
            formattedName = formattedName + word.capitalized + "-"
        }
        formattedName = String(formattedName.dropLast())
        let ref = FirebaseManager.shared.storage.reference(withPath: formattedName)
        
        guard let imageData = imageToUpload?.jpegData(compressionQuality: 0.5) else { return }
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                self.awaitfileUpload = true
                self.uploadedSuccessfully = false
                self.uploadErrMessage = "\(err)"
                self.uploadInProgress = false
                return
            }
            ref.downloadURL { url, err in
                if let err = err {
                    self.awaitfileUpload = true
                    self.uploadedSuccessfully = false
                    self.uploadErrMessage = "\(err)"
                    self.uploadInProgress = false
                    return
                }
                self.storeUserInformation(file: url!, tag: tag, name: formattedName)
                self.awaitfileUpload = true
                self.uploadedSuccessfully = true
                self.uploadInProgress = false
            }
        }
    }
    
    func storeUserInformation(file: URL, tag: String, name: String) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
//        guard let email = FirebaseManager.shared.auth.currentUser?.email else { return }
        let userData = ["url": file.absoluteString, "tag": tag]
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).collection("files").document(name)
            .setData(userData) { err in
                if let err = err {
                    print("Failed to store data: \(err)")
                    return
                }
                print("Successfully stored data")
            }
    }
}

class download: ObservableObject {
    func retrieveImage(completion: @escaping (([String]) -> Void)) -> Void {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            print("Failed to find user uid")
            return
        }
        
        let main = FirebaseManager.shared.firestore.collection("users")
            .document(uid).collection("files")
        main.getDocuments { snapshot, err in
            if let err = err {
                print("Failed to retrieve current user: \(err)")
                return
            }
            guard let data = snapshot?.documents else { return }
            var dataFinal: [String] = []
            for each in data {
//                print(each.documentID as! String) // prints document name
//                print(each["url"] as! String)
                dataFinal.append(each["url"] as! String)
            }
            completion(dataFinal)
        }
    }
}

struct ImageUpload: View {
    @State var image: UIImage?
    @State var shouldShowImagePicker = false
    @State var tags = ["Le Outdoors", "Le Fall o' Agua"]
    @State var tagSelectionUpload = "Le Outdoors"
    @State var fileNameUpload = ""
    
    @ObservedObject var u = upload()
    
    var body: some View {
        if(!u.uploadInProgress){
            if(!u.awaitfileUpload){
                VStack(spacing: 60){
                    VStack {
                        Button {
                            shouldShowImagePicker.toggle()
                        } label: {
                            VStack {
                                if let image = self.image {
                                    Image(uiImage: image).displayImage()
                                    Text("Click to Replace").mediumText()
                                } else {
                                    VStack{
                                        VStack{
                                            Image(systemName: "icloud.and.arrow.up").uploadImageButton()
                                            Text("Upload Image").largeText()
                                        }.padding(35)
                                    }.uploadContainer()
                                }
                            }
                        }
                    }
                    if self.image != nil {
                        Picker("Select a tag", selection: $tagSelectionUpload) {
                            ForEach(tags, id: \.self) {
                                Text($0)
                            }
                        }.pickerStyle(.menu)
                        TextField("File Name", text: $fileNameUpload)
                        Button(action: {
                            u.persistImageToStorage(image: image, tag: tagSelectionUpload, name: fileNameUpload)
                        }) { Text("Publish Image").mediumText().padding(15) }.publishButton().padding()
                    }
                }
                .padding()
                .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {ImagePicker(image: $image)}
            } else {
                if(u.uploadedSuccessfully == true){
                    VStack(spacing: 30){
                        Image(systemName: "checkmark.icloud")
                            .uploadIcon()
                            .foregroundColor(Color("Google Green"))
                        Text("Image Published").largeText()
                        Button(action: {u.reset(); self.image = nil}){
                            Text("Dismiss").mediumText().padding(15)
                        }.publishButton().padding()
                    }
                } else {
                    VStack(spacing: 30){
                        Image(systemName: "exclamationmark.icloud")
                            .uploadIcon()
                            .foregroundColor(Color("Google Red"))
                        Text("Failed to Publish").largeText()
                        Button(action: {u.reset()}){
                            Text("Try Again").mediumText().padding(15)
                        }.publishButton().padding()
                    }
                }
            }
        } else {
            VStack(spacing: 30){
                Image(systemName: "link.icloud")
                    .uploadIcon()
                    .foregroundColor(Color(.gray))
                Text("Publishing Image").largeText()
            }
        }
    }
}
