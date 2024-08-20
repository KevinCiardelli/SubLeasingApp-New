import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct ListView: View {
    //Accessing our database and grabbing all available objects under type Location
    @FirestoreQuery(collectionPath: "Locations") var locations: [Location]

    //Getting access to dismiss a page
    @Environment (\.dismiss) private var dismiss

    //Boolean variable for sheet presentation for creating a new Location
    @State private var sheetIsPresented = false

    //Boolean variable for sheet presentation for viewing Locations associated with the user
    @State private var myListingSheetIsPresented = false

    //Nav path to set up navigation for indivudal Location objects
    @State private var path = NavigationPath()

    var body: some View {
        ZStack {
            //using our variable path to bind the path we choose to the variable to maintain sync with the navstack
            NavigationStack(path: $path) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        //Accessing our initialized array from Firebase
                        ForEach(locations) { location in
                            NavigationLink {
                                LocationsDisplayView(location: location)
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    if let firstPhotoURL = location.photoURLs.first, let imageURL = URL(string: firstPhotoURL) {

                                        //Async loading so we do not block the main thread of the application while the image is loading
                                        //Also using phase to determine validity of the success of the image with switch cases
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
                                            //default icon if the picture does not load properly
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
                                        //default icon if their are no pictures
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
                                .frame(maxWidth: .infinity) 
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(radius: 10)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
                //navbar for navigation :)
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
                    //present the sheet to add a new location
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            sheetIsPresented.toggle()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .bold()
                        .foregroundColor(Color("BC"))
                    }
                    //present the sheet to view the locations tied to the users account
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
                //More sheet functionality
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
