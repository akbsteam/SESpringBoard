//
//  SESpringBoard.m
//  SESpringBoardDemo
//
//  Created by Sarp Erdag on 11/5/11.
//  Copyright (c) 2011 Sarp Erdag. All rights reserved.
//

#import "SESpringBoard.h"
#import "SEViewController.h"

@implementation SESpringBoard

@synthesize items, title, launcher, isInEditingMode, itemCounts;

- (IBAction) doneEditingButtonClicked {
    [self disableEditingMode];
}

- (id) initWithTitle:(NSString *)boardTitle items:(NSMutableArray *)menuItems image:(UIImage *) image{
    appSize = [[UIScreen mainScreen] applicationFrame].size;
    
    self = [super initWithFrame:CGRectMake(0, 0, appSize.width, appSize.height)];    
    
    if (self) {
        [self setUserInteractionEnabled:YES];

        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        hpad = 0;
        
        CGRect doneButton = CGRectMake(appSize.width - 55, 5, 50, 34.0);
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            itemSize = CGSizeMake(149, 149);
            cAppSize = CGSizeMake(768, 1024);
        }
        else
        {
            itemSize = CGSizeMake(100, 100);
            cAppSize = CGSizeMake(320, 480);
        }
        appSize = cAppSize;
        
        self.launcher = image;
        self.isInEditingMode = NO;
        
        // create the top bar
        self.title = boardTitle;
        navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, appSize.width, 44)];
        navigationBar.barStyle = UIBarStyleBlack;
        navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        // add a simple for displaying a title on the bar
        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, appSize.width, 44)];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = UITextAlignmentCenter;
        [titleLabel setText:title];
        [navigationBar addSubview:titleLabel];
        
        // add a button to the right side that will become visible when the items are in editing mode
        // clicking this button ends editing mode for all items on the springboard
        doneEditingButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        doneEditingButton.frame = doneButton;
        [doneEditingButton setTitle:@"Done" forState:UIControlStateNormal];
        doneEditingButton.backgroundColor = [UIColor clearColor];
        [doneEditingButton addTarget:self action:@selector(doneEditingButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [doneEditingButton setHidden:YES];
        [navigationBar addSubview:doneEditingButton];
        
        [self addSubview:navigationBar];
        
        // create a container view to put the menu items inside
        itemsContainer = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 50, appSize.width-20, appSize.height-60)];
        itemsContainer.delegate = self;
        [itemsContainer setScrollEnabled:YES];
        [itemsContainer setPagingEnabled:YES];
        itemsContainer.showsHorizontalScrollIndicator = NO;
        [self addSubview:itemsContainer];
        
        int nColsPerRow = floor((appSize.width-20) / itemSize.width);
        int itemsPerPage = floor((appSize.height-60) / itemSize.height) * nColsPerRow;
        
        int counter = 0;
        int numberOfPages = (ceil((float)[menuItems count] / itemsPerPage));
        self.items = [NSMutableArray arrayWithCapacity:numberOfPages];
        
        for (int i=0; i<numberOfPages; i++) {
            NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:itemsPerPage];
            [self.items insertObject:tmp atIndex:i];
        }

        for (SEMenuItem *item in menuItems) {
            int page = floor(counter / itemsPerPage);
            int pos = counter % itemsPerPage;

            NSMutableArray *pagelist = [self.items objectAtIndex:page];
            [pagelist insertObject:item atIndex:pos];
            
            item.tag = pos;
            item.delegate = self;
            [item setFrame:CGRectMake(0, 0, itemSize.width, itemSize.height)];
            [itemsContainer addSubview:item];
            
            counter++;
        }
        
        [itemsContainer setContentSize:CGSizeMake(numberOfPages*(appSize.width-20), itemsContainer.frame.size.height)];
        
        // add a page control representing the page the scrollview controls
        pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, (appSize.height-27), appSize.width, 20)];
        if (numberOfPages > 1) {
            pageControl.numberOfPages = numberOfPages;
            pageControl.currentPage = 0;
            [self addSubview:pageControl];
        }
        
        // add listener to detect close view events
        [[NSNotificationCenter defaultCenter]
            addObserver:self
            selector:@selector(closeViewEventHandler:)
            name:@"closeView"
            object:nil ];
    }
    return self;
}

+ (id) initWithTitle:(NSString *)boardTitle items:(NSMutableArray *)menuItems launcherImage:(UIImage *)image {
    SESpringBoard *tmpInstance = [[[SESpringBoard alloc] initWithTitle:boardTitle items:menuItems image:image] autorelease];
	return tmpInstance;
};

- (void)dealloc {
    [items release];
    [launcher release];
    [navigationBar release];
    [pageControl release];
    [itemCounts release];
    [titleLabel release];
    [itemsContainer release];
    [super dealloc];
}

// transition animation function required for the springboard look & feel
- (CGAffineTransform)offscreenQuadrantTransformForView:(UIView *)theView {
    CGPoint parentMidpoint = CGPointMake(CGRectGetMidX(theView.superview.bounds), CGRectGetMidY(theView.superview.bounds));
    CGFloat xSign = (theView.center.x < parentMidpoint.x) ? -1.f : 1.f;
    CGFloat ySign = (theView.center.y < parentMidpoint.y) ? -1.f : 1.f;
    return CGAffineTransformMakeTranslation(xSign * parentMidpoint.x, ySign * parentMidpoint.y);
}

#pragma mark - MenuItem Delegate Methods

- (void)launch:(int)tag :viewController {
    
    // if the springboard is in editing mode, do not launch any view controller
    if (isInEditingMode)
        return;
    
    // first disable the editing mode so that items will stop wiggling when an item is launched
    [self disableEditingMode];
    
    // create a navigation bar
    nav = [UINavigationController alloc];
    SEViewController *vc = viewController;
    
    // manually trigger the appear method
    [viewController viewDidAppear:YES];
    
    vc.launcherImage = launcher;
    [nav initWithRootViewController:viewController];
    [nav viewDidAppear:YES];
    
    nav.view.alpha = 0.f;
    nav.view.transform = CGAffineTransformMakeScale(.1f, .1f);
    [self addSubview:nav.view];
    
    [UIView animateWithDuration:.3f  animations:^{
        // fade out the buttons
        for(SEMenuItem *item in self.items) {
            item.transform = [self offscreenQuadrantTransformForView:item];
            item.alpha = 0.f;
        }
        
        // fade in the selected view
        nav.view.alpha = 1.f;
        nav.view.transform = CGAffineTransformIdentity;
        [nav.view setFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
        
        // fade out the top bar
        [navigationBar setFrame:CGRectMake(0, -44, appSize.width, 44)];
    }];
}

- (void)removeFromSpringboard:(int)index
{
    NSMutableArray *pagelist = [self.items objectAtIndex:pageControl.currentPage];
    
    // Remove the selected menu item from the springboard, it will have a animation while disappearing
    SEMenuItem *menuItem = [pagelist objectAtIndex:index];
    [menuItem removeFromSuperview];
    
    int numberOfItemsInCurrentPage = [pagelist count];
    int remainingNumberOfItemsInPage = numberOfItemsInCurrentPage - index;
    
    int nColsPerRow = floor((appSize.width-20) / itemSize.width);
    
    // Select the items listed after the deleted menu item
    // and move each of the ones on the current page, one step back.
    // The first item of each row becomes the last item of the previous row.
    for (int i = index+1; i<[pagelist count]; i++) {
        SEMenuItem *item = [pagelist objectAtIndex:i];   
        [UIView animateWithDuration:0.2 animations:^{
            
            // Only reposition the items in the current page, coming after the current item
            if (i < index + remainingNumberOfItemsInPage) {
                // Check if it is the first item in the row
                if (item.tag % nColsPerRow == 0) {
                    [item setFrame:CGRectMake(item.frame.origin.x+((nColsPerRow-1)*itemSize.width), item.frame.origin.y-(itemSize.height - 5), item.frame.size.width, item.frame.size.height)];
                } else {
                    [item setFrame:CGRectMake(item.frame.origin.x-itemSize.width, item.frame.origin.y, item.frame.size.width, item.frame.size.height)];
                }
            }            
            
            // Update the tag to match with the index. Since the an item is being removed from the array, 
            // all the items' tags coming after the current item has to be decreased by 1.
            [item updateTag:item.tag-1];
        }]; 
    }
    
    // remove the item from the array of items
    [pagelist removeObjectAtIndex:index];
    
    // if the pagelist is now empty we need to get rid of the page
    if ([pagelist count] == 0) {
        int newPage = pageControl.currentPage - 1;
        if (newPage < 0) { newPage = 0; }
        
        [self.items removeObjectAtIndex:pageControl.currentPage];
        
        int numberOfPages = [self.items count];
        
        [itemsContainer setContentSize:CGSizeMake(numberOfPages*(appSize.width-20), itemsContainer.frame.size.height)];
        
        pageControl.numberOfPages = numberOfPages;
        pageControl.currentPage = newPage;
        
        if ([self.items count] == 1) {
            [pageControl removeFromSuperview];
        }
    }
}

- (void)layoutItems {
    int nColsPerRow = floor((appSize.width-20) / itemSize.width);
    int itemsPerPage = floor((appSize.height-60) / itemSize.height) * nColsPerRow;

    int numberOfPages = [self.items count];
    
    itemsContainer.frame = CGRectMake(10, 50, appSize.width-20, appSize.height-60);
    [itemsContainer setContentSize:CGSizeMake(numberOfPages*(appSize.width-20), itemsContainer.frame.size.height)];
    
    titleLabel.frame = CGRectMake(0, 0, appSize.width, 44);
    pageControl.frame = CGRectMake(0, (appSize.height-57), appSize.width, 20);
    
    int counter = 0;
    int horgap = 0;
    int vergap = 0;
    int currentPage = 0;
    
    for (NSMutableArray *pagelist in self.items) {
        for (SEMenuItem *item in pagelist) {
            [item setFrame:CGRectMake(horgap + hpad + (currentPage*(appSize.width-20)), vergap, itemSize.width, itemSize.height)];
            
            horgap = horgap + itemSize.width + hpad;
            counter = counter + 1;
            
            if(counter % nColsPerRow == 0){
                vergap = vergap + itemSize.height - 5;
                horgap = 0;
            }
            
            if (counter % itemsPerPage == 0) {
                vergap = 0;
                horgap = 0;
            }
        }
        
        currentPage++;
    }
}

- (void)closeViewEventHandler: (NSNotification *) notification {
    UIView *viewToRemove = (UIView *) notification.object;    
    [UIView animateWithDuration:.3f animations:^{
        viewToRemove.alpha = 0.f;
        viewToRemove.transform = CGAffineTransformMakeScale(.1f, .1f);
        for(SEMenuItem *item in self.items) {
            item.transform = CGAffineTransformIdentity;
            item.alpha = 1.f;
        }
        [navigationBar setFrame:CGRectMake(0, 0, appSize.width, 44)];
    } completion:^(BOOL finished) {
        [viewToRemove removeFromSuperview];
    }];
    
    // release the dynamically created navigation bar
    [nav release];
}

#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    CGFloat pageWidth = itemsContainer.frame.size.width;
    int page = floor((itemsContainer.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    pageControl.currentPage = page;
}

#pragma mark - Custom Methods

- (void) disableEditingMode
{
    // loop thu all the items of the board and disable each's editing mode
    for (NSMutableArray *pagelist in self.items) {
        for (SEMenuItem *item in pagelist) {
            [item disableEditing];
        }
    }      
    
    [doneEditingButton setHidden:YES];
    self.isInEditingMode = NO;
}

- (void) enableEditingMode
{
    for (NSMutableArray *pagelist in self.items) {
        for (SEMenuItem *item in pagelist) {
            [item enableEditing];
        }
    }
    
    // show the done editing button
    [doneEditingButton setHidden:NO];
    self.isInEditingMode = YES;
}

#pragma mark - KVO for Rotation

- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    if ([keyPath isEqualToString:@"viewIsCurrentlyPortrait"]) {
        NSNumber *newObject = [change objectForKey:NSKeyValueChangeNewKey];

        if ([newObject boolValue]) {
            appSize = cAppSize;
            hpad = 0;

        } else {
            appSize = CGSizeMake(cAppSize.height, cAppSize.width);
            hpad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 15 : 0;
        }
        
        // NSLog(@"viewIsCurrentlyPortrait %d", [newObject intValue]);
        // NSLog(@"appsize %@", NSStringFromCGSize(appSize));
        
        [self layoutItems];
    }
}

@end
