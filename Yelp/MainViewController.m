//
//  MainViewController.m
//  Yelp
//
//  Created by Timothy Lee on 3/21/14.
//  Copyright (c) 2014 codepath. All rights reserved.
//

#import "MainViewController.h"
#import "YelpClient.h"
#import "Business.h"
#import "BusinessCell.h"
#import "FiltersViewController.h"

NSString * const kYelpConsumerKey = @"vxKwwcR_NMQ7WaEiQBK_CA";
NSString * const kYelpConsumerSecret = @"33QCvh5bIF5jIHR5klQr7RtBDhQ";
NSString * const kYelpToken = @"uRcRswHFYa1VkDrGV6LAW2F8clGh5JHV";
NSString * const kYelpTokenSecret = @"mqtKIxMIR4iBtBPZCmCLEb-Dz3Y";
NSString * const DEFAULT_SEARCH_QUERY = @"Restaurants";
int const ROWHEIGHTCONSTANT = 85;

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate, FiltersViewControllerDelegate, UISearchBarDelegate>

@property (nonatomic, strong) YelpClient *client;
@property (nonatomic, strong) NSMutableArray * businesses;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) BusinessCell *prototypeBusinessCell;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) FiltersViewController *filterVC;
@property (nonatomic ,assign) BOOL infiniteLoading;
@property (nonatomic, strong) NSMutableDictionary *filters;

- (void)onFilterButton;
- (void)fetchBusinessesWithQuery:(NSString *)query params:(NSDictionary *)params;
@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // You can register for Yelp API keys here: http://www.yelp.com/developers/manage_api_keys
        self.client = [[YelpClient alloc] initWithConsumerKey:kYelpConsumerKey consumerSecret:kYelpConsumerSecret accessToken:kYelpToken accessSecret:kYelpTokenSecret];
        [self fetchBusinessesWithQuery:DEFAULT_SEARCH_QUERY params:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.infiniteLoading = YES;
    self.filters = [NSMutableDictionary dictionary];
    self.businesses = [NSMutableArray array];
    
    // nav bar
    self.title = @"Yelp";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStylePlain target:self action:@selector(onFilterButton)];
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.delegate = self;
    self.navigationItem.titleView = self.searchBar;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    // yelp RGB: (196, 18, 0)
    self.navigationController.navigationBar.barTintColor = [UIColor  colorWithRed:196.0f/255.0f green:18.0f/255.0f blue:0.0f/255.0f alpha:1.0f];
    
    // setup table view
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"BusinessCell" bundle:nil] forCellReuseIdentifier:@"BusinessCell"];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = ROWHEIGHTCONSTANT;
    
    // setup filters view controller
    self.filterVC = [[FiltersViewController alloc] init];
    self.filterVC.delegate = self;
}


#pragma mark - Table View Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.businesses.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BusinessCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BusinessCell"];
    cell.business = self.businesses[indexPath.row];
    
    // if reaching last row, trigger infinite loading with 'offset' filter
    if ((indexPath.row >= self.businesses.count - 1) && self.infiniteLoading) {
        NSMutableDictionary *tempFilters = [self.filters mutableCopy];
        [tempFilters setObject:@(self.businesses.count) forKey:@"offset"];
        [self fetchBusinessesWithQuery:DEFAULT_SEARCH_QUERY params:tempFilters];
    }
    // NSLog(@"cell.business = %@", cell.business);
    return cell;
}

#pragma mark - Search Bar Methods

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    //TODO: pass in filters
    [self fetchBusinessesWithQuery:searchText params:nil];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    //TODO: pass in filters
    [self fetchBusinessesWithQuery:searchBar.text params:nil];
}

#pragma mark - Filter Delegate Methods

- (void)filtersViewController:(FiltersViewController *)filtersViewController didChangeFilters:(NSDictionary *)filters {
    self.filters = [filters mutableCopy];
    
    // turning off infinite loading for this query will reset self.businesses
    self.infiniteLoading = NO;
    [self fetchBusinessesWithQuery:DEFAULT_SEARCH_QUERY params:self.filters];
    
    NSLog(@"New Filters: %@", filters);
}

#pragma mark - Private Method

- (void)onFilterButton {
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:self.filterVC];
    [self presentViewController:nvc animated:YES completion:nil];
}

-(void) fetchBusinessesWithQuery:(NSString *)query params:(NSDictionary *)params {
    // search yelp
    [self.client searchWithTerm:query params:params success:^(AFHTTPRequestOperation *operation, id response) {
        // NSLog(@"response: %@", response);
        NSArray *tempBusinessDictionaries = response[@"businesses"];
        NSMutableArray *businessDictionaries = [Business businessesWithDictionaries:tempBusinessDictionaries];
        
        if (self.infiniteLoading) {
            [self.businesses addObjectsFromArray:businessDictionaries];
        } else {
            self.businesses = businessDictionaries;
            self.infiniteLoading = YES;
        }
        [self.tableView reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", [error description]);
        
        // display cell that says Sorry Not Found'
    }];

}


@end
