////
////  WordsView.swift
////  homie-ios
////
////  Created by Diego Lares on 8/16/23.
////
//
//import SwiftUI
//
//struct WordsView: View {
//    @EnvironmentObject var viewModel: ContentViewModel
//
//    var body: some View {
//        ScrollView(.vertical) {
//            Group { // Wrap VStack inside a Group
//                VStack(spacing: 15) {
//                    if viewModel.usersSet {
//                        ForEach(viewModel.words.indices, id: \.self) { index in
//                            if let user = viewModel.usersMapping[viewModel.words[index].postedBy._ref] {
//                                WordView(
//                                    word: viewModel.words[index],
//                                    user: user
//                                )
//                            }
//                        }
//                    }
//                    Spacer()
//                }
//            }
//            //.padding(10)
//            .id(viewModel.usersSet) // Use .id() to trigger view update
//        }
//        .background(Color.black)
//    }
//}
//
////struct WordsView_Previews: PreviewProvider {
////    static var previews: some View {
////        WordsView(viewModel: ContentViewModel)
////    }
////}
