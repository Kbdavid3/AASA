//
//  IGStoryPreviewModel.swift
//  InstagramStories
//
//  Created by Boominadha Prakash on 18/03/18.
//  Copyright © 2018 DrawRect. All rights reserved.
//

import Foundation

class IGStoryPreviewModel: NSObject {
    
    //MARK:- iVars
    let stories: [IGStory]
    let handPickedStoryIndex: Int //starts with(i)
    
    //MARK:- Init method
    init(_ stories: [IGStory], _ handPickedStoryIndex: Int) {
        self.stories = stories
        self.handPickedStoryIndex = handPickedStoryIndex
    }
    
    //MARK:- Functions
    func numberOfItemsInSection(_ section: Int) -> Int {
            return stories.count
    }
    func cellForItemAtIndexPath(_ indexPath: IndexPath) -> IGStory? {
        if indexPath.item < stories.count {
            return stories[indexPath.item]
        } else {
            print("⚠️ IGStoryPreviewModel: Stories Index mis-matched - requested index: \(indexPath.item), total stories: \(stories.count)")
            return nil
        }
    }
}
