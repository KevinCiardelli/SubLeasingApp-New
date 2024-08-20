import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct ListView: View {
    @FirestoreQuery(collectionPath: "Locations") var locations: [Location]

    @Environment (\.dismiss) private var dismiss
    @State private var sheetIsPresented = false
    @State private var myListingSheetIsPresented = false
    @State private var path = NavigationPath()

    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ForEach(locations) { location in
                            NavigationLink {
                                LocationsDisplayView(location: location)
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    if let firstPhotoURL = location.photoURLs.first, let imageURL = URL(string: firstPhotoURL) {
                                        AsyncImage(url: imageURL) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .frame(height: 250)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(height: 250)
                                                    .cornerRadius(15)
                                                    .shadow(radius: 5)
                                            case .failure:
                                                Image(systemName: "house.fill")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: 250)
                                                    .cornerRadius(15)
                                                    .foregroundColor(Color("BC"))
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    } else {
                                        Image(systemName: "house.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 250)
                                            .cornerRadius(15)
                                            .foregroundColor(Color("BC"))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(location.address)
                                            .font(.title2)
                                            .bold()
                                            .foregroundColor(Color("BC"))
                                        
                                        Text("Asking: \(Int(location.numberValue)).00")
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                        
                                        Text("\(location.number_of_bedrooms) Rooms")
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                    }
                                    .padding([.leading, .trailing, .bottom])
                                }
                                .frame(maxWidth: .infinity) // Make sure it fills the width
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(radius: 10)
                                .padding(.horizontal) // Padding to give space on the sides
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Sign Out") {
                            do {
                                try Auth.auth().signOut()
                                print("Log Out")
                                dismiss()
                            } catch {
                                print("Could not log out")
                            }
                        }
                        .bold()
                        .foregroundColor(Color("BC"))
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            sheetIsPresented.toggle()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .bold()
                        .foregroundColor(Color("BC"))
                    }
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            myListingSheetIsPresented.toggle()
                        } label: {
                            Text("View Your Listings")
                                .bold()
                                .foregroundColor(Color("BC"))
                        }
                    }
                }
                .fullScreenCover(isPresented: $sheetIsPresented) {
                    NavigationStack {
                        NewLocationDetailView(location: Location())
                    }
                }
                .fullScreenCover(isPresented: $myListingSheetIsPresented) {
                    NavigationStack {
                        UserListingViews()
                    }
                }
                .navigationTitle("Subleases for BC")
                .foregroundColor(Color("BC"))
            }
        }
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ListView()
        }
    }
}
