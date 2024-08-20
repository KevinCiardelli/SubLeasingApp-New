//
//  LocationsDisplayView.swift
//  FinalProject
//
//  Created by Kevin Ciardelli on 4/27/23.
//

import SwiftUI
import MapKit
import Firebase
import FirebaseFirestoreSwift
import UIKit


struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct ContactInfoView: View {
    let phone: String
    let email: String
    var onClose: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                
                HStack {
                    Spacer()
                    Button(action: {
                        onClose()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                            .padding(.trailing, 10)
                            .padding(.top, 10)
                    }
                }
                
                
                Text("Contact Information")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                
                if let phoneURL = URL(string: "tel:\(phone)"), UIApplication.shared.canOpenURL(phoneURL) {
                    Link(destination: phoneURL) {
                        HStack {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 20))
                            Text("Call: \(phone)")
                                .font(.system(size: 18))
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                    }
                } else {
                    Text("Phone: \(phone)")
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                }
                
                
                if let emailURL = URL(string: "mailto:\(email)"), UIApplication.shared.canOpenURL(emailURL) {
                    Link(destination: emailURL) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 20))
                            Text("Email: \(email)")
                                .font(.system(size: 18))
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                    }
                } else {
                    Text("Email: \(email)")
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(BlurView(style: .systemUltraThinMaterial))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding()
            Spacer()
        }
    }
}

struct LocationsDisplayView: View {

    struct Annotation: Identifiable {
        let id = UUID().uuidString
        var name: String
        var address: String
        var coordinate: CLLocationCoordinate2D
    }
    
    @Environment(\.dismiss) private var dismiss
    @State var location: Location
    @State private var mapRegion = MKCoordinateRegion()
    @State private var annotations: [Annotation] = []
    @State private var isShowingMailView = false
    @FirestoreQuery(collectionPath: "Locations") var photos: [Photo]
    var previewRunning = false
    
    let regionSize = 500.0
    
    var body: some View {
        ScrollView(showsIndicators: true) {
            VStack(alignment: .leading) {
                
                
                if !location.photoURLs.isEmpty {
                    TabView {
                        ForEach(location.photoURLs, id: \.self) { url in
                            if let imageURL = URL(string: url) {
                                AsyncImage(url: imageURL) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(height: 300)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 300)
                                            .cornerRadius(0)
                                            .clipped()
                                    case .failure:
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 300)
                                            .foregroundColor(.gray)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 300)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(height: 300)
                    .tabViewStyle(PageTabViewStyle())
                }

                VStack(alignment: .leading, spacing: 16) {
                    
                    Text(location.address)
                        .font(.title)
                        .bold()
                        .padding([.leading, .trailing])
                    
                    
                    HStack {
                        Text("Asking: $\(Int(location.numberValue)).00")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("\(location.number_of_bedrooms) Beds")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("\(location.parking ? "Parking Available" : "No Parking")")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding([.leading, .trailing])

                    Divider()

                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amenities")
                            .font(.headline)
                            .bold()
                        
                        Text(location.ammenities)
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .padding([.leading, .trailing])

                    Divider()

                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.headline)
                            .bold()

                        Map(coordinateRegion: $mapRegion, annotationItems: annotations) { annotation in
                            MapMarker(coordinate: annotation.coordinate)
                        }
                        .frame(height: 200)
                        .cornerRadius(10)
                    }
                    .padding([.leading, .trailing])

                    Divider()

                    
                    Button(action: {
                        withAnimation {
                            isShowingMailView.toggle()
                        }
                    }) {
                        Text("Contact Information")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding([.leading, .trailing, .bottom])
                    
                }
                .background(Color.white)
                .cornerRadius(20)
                .padding([.leading, .trailing], 10)
                .shadow(radius: 10)
            }
            .background(Color.gray.opacity(0.1))
            .edgesIgnoringSafeArea(.top)
            .onAppear {
                if !previewRunning {
                    $photos.path = "Locations/\(location.id ?? "")/photos"
                    print("photos.path = \($photos.path)")
                }
                
                if location.id != nil {
                    mapRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionSize, longitudinalMeters: regionSize)
                } else {
                    print("shouldn't be here")
                }
                
                annotations = [Annotation(name: location.name, address: location.address, coordinate: location.coordinate)]
            }
        }
        .sheet(isPresented: $isShowingMailView) {
            ContactInfoView(phone: location.phone, email: location.email) {
                withAnimation {
                    isShowingMailView = false
                }
            }
        }
    }
}

struct LocationsDetailView_Previews: PreviewProvider {
    static var previews: some View {
        LocationsDisplayView(location: Location(), previewRunning: true)
    }
}
