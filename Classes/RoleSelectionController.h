//  This file is part of iNetHack.
//
//  iNetHack is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, version 2 of the License only.
//
//  iNetHack is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with iNetHack.  If not, see <http://www.gnu.org/licenses/>.

#import <UIKit/UIKit.h>

@protocol RoleSelectionControllerDelegate
- (void)didCompleteRoleSelection:(id)sender;
@end

@interface RoleSelectionController : NSObject
{
	UINavigationController *navigationController;
	id delegate;
}
@property (assign) id delegate;
+ (id)roleSelectorWithNavigationController:(UINavigationController *)navController;
- (void)start;
@end
