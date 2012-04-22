//
//  SEMenuItem.h
//  SESpringBoardDemo
//
//  Created by Sarp Erdag on 11/5/11.
//  Copyright (c) 2011 Sarp Erdag. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MenuItemDelegate;
@interface SEMenuItem : UIView {
    UIButton *removeButton;   
}

@property (nonatomic, assign) int tag;
@property BOOL isRemovable;
@property BOOL isInEditingMode;
@property (nonatomic, retain) NSString *viewControllerClass;
@property (nonatomic, retain) NSString *image;
@property (nonatomic, retain) NSString *titleText;
@property (nonatomic, assign) id <MenuItemDelegate> delegate;

- (id) initWithTitle:(NSString *)title image:(NSString *)imageName vc:(NSString *)viewController removable:(BOOL)removable;
+ (id) initWithTitle:(NSString *)title imageName:(NSString *)imageName viewController:(NSString *)viewController removable:(BOOL)removable;

- (void) enableEditing;
- (void) disableEditing;
- (void) updateTag:(int) newTag;

@end

@protocol MenuItemDelegate <NSObject>
@optional

- (void)launch:(int)index with:(NSString *)viewController;
- (void)removeFromSpringboard:(int)index;

@end