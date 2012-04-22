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
    CGSize appSize = [[UIScreen mainScreen] applicationFrame].size;
    
    self = [super initWithFrame:CGRectMake(0, 0, appSize.width, appSize.height)];

    [self setUserInteractionEnabled:YES];
    
    if (self) {
        
        int itemHeight;
        int itemWidth;
        CGRect doneButton = CGRectMake(appSize.width - 55, 5, 50, 34.0);
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            itemWidth = 149;
            itemHeight = 149;
        }
        else
        {
            itemWidth = 100;
            itemHeight = 100;
        }
        
        self.launcher = image;
        self.isInEditingMode = NO;
        
        // create the top bar
        self.title = boardTitle;
        navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, appSize.width, 44)];
        navigationBar.barStyle = UIBarStyleBlack;
        
        // add a simple for displaying a title on the bar
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, appSize.width, 44)];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = UITextAlignmentCenter;
        [titleLabel setText:title];
        [navigationBar addSubview:titleLabel];
        [titleLabel release];
        
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
        
        int nColsPerRow = floor((appSize.width-20) / itemWidth);
        int itemsPerPage = floor((appSize.height-60) / itemHeight) * nColsPerRow;
        
        self.items = menuItems;
        int counter = 0;
        int horgap = 0;
        int vergap = 0;
        int numberOfPages = (ceil((float)[menuItems count] / itemsPerPage));
        int currentPage = 0;
        
        for (SEMenuItem *item in self.items) {
            currentPage = counter / itemsPerPage;
            item.tag = counter;
            item.delegate = self;
            [item setFrame:CGRectMake(item.frame.origin.x + horgap + (currentPage*(appSize.width-20)), item.frame.origin.y + vergap, itemWidth, itemHeight)];
            [itemsContainer addSubview:item];
            horgap = horgap + itemWidth;
            counter = counter + 1;
            
            if(counter % nColsPerRow == 0){
                vergap = vergap + itemHeight - 5;
                horgap = 0;
            }
            
            if (counter % itemsPerPage == 0) {
                vergap = 0;
                horgap = 0;
            }
        }
        
        // record the item counts for each page
        self.itemCounts = [NSMutableArray array];
        int totalNumberOfItems = [self.items count];
        int numberOfFullPages = totalNumberOfItems % itemsPerPage;
        int lastPageItemCount = totalNumberOfItems - numberOfFullPages%itemsPerPage;
        for (int i=0; i<numberOfFullPages; i++)
            [self.itemCounts addObject:[NSNumber numberWithInteger:itemsPerPage]];
        if (lastPageItemCount != 0)
            [self.itemCounts addObject:[NSNumber numberWithInteger:lastPageItemCount]];
        
        [itemsContainer setContentSize:CGSizeMake(numberOfPages*(appSize.width-20), itemsContainer.frame.size.height)];
        [itemsContainer release];

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
    
    CGSize appSize = [[UIScreen mainScreen] applicationFrame].size;
    
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
    // Remove the selected menu item from the springboard, it will have a animation while disappearing
    SEMenuItem *menuItem = [items objectAtIndex:index];
    [menuItem removeFromSuperview];
    
    CGSize appSize = [[UIScreen mainScreen] applicationFrame].size;
    int w = (int) (appSize.width - 20);
    
    int numberOfItemsInCurrentPage = [[self.itemCounts objectAtIndex:pageControl.currentPage] intValue];
    
    // First find the index of the current item with respect of the current page
    // so that only the items coming after the current item will be repositioned.
    // The index of the item can be found by looking at its coordinates
    int mult = ((int)menuItem.frame.origin.y) / 95;
    int add = ((int)menuItem.frame.origin.x % w)/100;
    int pageSpecificIndex = (mult*3) + add;
    int remainingNumberOfItemsInPage = numberOfItemsInCurrentPage-pageSpecificIndex;
    
    int itemHeight;
    int itemWidth;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        itemWidth = 149;
        itemHeight = 149;
    }
    else
    {
        itemWidth = 100;
        itemHeight = 100;
    }
    
    int nColsPerRow = floor((appSize.width-20) / itemWidth);
    
    // Select the items listed after the deleted menu item
    // and move each of the ones on the current page, one step back.
    // The first item of each row becomes the last item of the previous row.
    for (int i = index+1; i<[items count]; i++) {
        SEMenuItem *item = [items objectAtIndex:i];   
        [UIView animateWithDuration:0.2 animations:^{
            
            // Only reposition the items in the current page, coming after the current item
            if (i < index + remainingNumberOfItemsInPage) {
                
                int intVal = item.frame.origin.x;
                // Check if it is the first item in the row
                if (intVal % nColsPerRow == 0)
                    [item setFrame:CGRectMake(item.frame.origin.x+((nColsPerRow-1)*itemWidth), item.frame.origin.y-(itemHeight - 5), item.frame.size.width, item.frame.size.height)];
                else 
                    [item setFrame:CGRectMake(item.frame.origin.x-itemWidth, item.frame.origin.y, item.frame.size.width, item.frame.size.height)];
            }            
            
            // Update the tag to match with the index. Since the an item is being removed from the array, 
            // all the items' tags coming after the current item has to be decreased by 1.
            [item updateTag:item.tag-1];
        }]; 
    }
    // remove the item from the array of items
    [items removeObjectAtIndex:index];
    // also decrease the record of the count of items on the current page and save it in the array holding the data
    numberOfItemsInCurrentPage--;
    [self.itemCounts replaceObjectAtIndex:pageControl.currentPage withObject:[NSNumber numberWithInteger:numberOfItemsInCurrentPage]];
}

- (void)closeViewEventHandler: (NSNotification *) notification {
    CGSize appSize = [[UIScreen mainScreen] applicationFrame].size;
    
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

- (void) disableEditingMode {
    // loop thu all the items of the board and disable each's editing mode
    for (SEMenuItem *item in items)
        [item disableEditing];
    
    [doneEditingButton setHidden:YES];
    self.isInEditingMode = NO;
}

- (void) enableEditingMode {
    
    for (SEMenuItem *item in items)
        [item enableEditing];
    
    // show the done editing button
    [doneEditingButton setHidden:NO];
    self.isInEditingMode = YES;
}

@end
