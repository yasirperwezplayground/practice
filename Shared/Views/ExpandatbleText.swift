//
//  ExpandatbleText.swift
//  TCAPractice
//
//  Created by Mohammad Yasir Perwez on 08.08.22.
//

import SwiftUI

struct ExpandableText: View {
    @State private var expanded: Bool = false
    @State private var truncated: Bool = false
    private var text: String

    let lineLimit: Int

    init(_ text: String, lineLimit: Int) {
        self.text = text
        self.lineLimit = lineLimit
    }

    private var moreLessText: String {
        if !truncated {
            return ""
        } else {
            return self.expanded ? "read less" : " read more"
        }
    }
    
  var body: some View {
    VStack(alignment: .leading) {
    GeometryReader { reader in
      let _ = print("DDDD \(reader.size)")
      Text(text)
        .lineLimit(expanded ? nil : lineLimit)
        .background(
          Text(text).lineLimit(lineLimit)
            .background(GeometryReader { visibleTextGeometry in
              ZStack { //large size zstack to contain any size of text
                Text(self.text)
                  .background(GeometryReader { fullTextGeometry in
                    Color.clear.onAppear {
                      self.truncated = fullTextGeometry.size.height > visibleTextGeometry.size.height
                    }
                  })
              }
              .frame(height: .greatestFiniteMagnitude)
            })
            .hidden() //keep hidden
        )
      if truncated {
        Button(action: {
          withAnimation {
            expanded.toggle()
          }
        }, label: {
          Text(moreLessText)
        })
      }
    }
    }.frame(height: 400)
    Spacer()
    }
}


struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    VStack(alignment: .leading, spacing: 10) {
        ExpandableText("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Sed ut laborum", lineLimit: 6)
        ExpandableText("Small text", lineLimit: 3)
        ExpandableText("Render the limited text and measure its size, R", lineLimit: 1)
        ExpandableText("Create a ZStack with unbounded height to allow the inner Text as much, Render the limited text and measure its size, Hide the background Indicates whether the text has been truncated in its display.", lineLimit: 3)
        
        
    }.padding()
  }
}
