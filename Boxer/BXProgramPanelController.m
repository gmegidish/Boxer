/* 
 Boxer is copyright 2009 Alun Bestor and contributors.
 Boxer is released under the GNU General Public License 2.0. A full copy of this license can be
 found in this XCode project at Resources/English.lproj/GNU General Public License.txt, or read
 online at [http://www.gnu.org/licenses/gpl-2.0.txt].
 */


#import "BXProgramPanelController.h"
#import "BXValueTransformers.h"
#import "BXSession+BXFileManager.h"
#import "BXProgramPanel.h"
#import "BXEmulator.h"


@implementation BXProgramPanelController
@synthesize programChooserPanel, defaultProgramPanel, noProgramsPanel, programList;

+ (NSSet *)keyPathsForValuesAffectingLabelForToggle
{
	return [NSSet setWithObject: @"representedObject.activeProgramPath"];
}

+ (NSSet *)keyPathsForValuesAffectingActiveProgramIsDefault
{
	return [NSSet setWithObjects:
			@"representedObject.activeProgramPath",
			@"representedObject.gamePackage.targetPath",
			nil];
}

+ (void) initialize
{
	id displayPath	= [[BXDisplayPathTransformer alloc]	initWithJoiner: @" ▸ " maxComponents: 3]; 
	id iconSize		= [[BXImageSizeTransformer alloc]	initWithSize: NSMakeSize(16, 16)];
	id fileName		= [[BXDOSFilenameTransformer alloc] init];

	[NSValueTransformer setValueTransformer: [iconSize autorelease]		forName: @"BXProgramIconSize"];
	[NSValueTransformer setValueTransformer: [displayPath autorelease]	forName: @"BXProgramDisplayPath"];
	[NSValueTransformer setValueTransformer: [fileName autorelease]		forName: @"BXDOSFilename"];
}

- (void) dealloc
{
	[self setProgramChooserPanel: nil],	[programChooserPanel release];
	[self setDefaultProgramPanel: nil],	[defaultProgramPanel release];
	[self setNoProgramsPanel: nil],		[noProgramsPanel release];
	[super dealloc];
}

- (void) setRepresentedObject: (id)session
{
	[[self representedObject] removeObserver: self forKeyPath: @"activeProgramPath"];
	[super setRepresentedObject: session];
	[[self representedObject] addObserver: self forKeyPath: @"activeProgramPath" options: 0 context: nil];
}

//Whenever the active program changes, change which view is drawn
- (void)observeValueForKeyPath: (NSString *)keyPath
					  ofObject: (id)object
						change: (NSDictionary *)change
					   context: (void *)context
{	
	if ([keyPath isEqualToString: @"activeProgramPath"]) [self syncActivePanel];
}

- (void) setView: (NSView *)view
{
	[super setView: view];
	//This will pull our subsidiary views from our own NIB file
	[self loadView];
}

- (void) syncActivePanel
{	
	BXSession *session = [self representedObject];
	NSView *panel;
	
	if		([session activeProgramPath])	panel = [self defaultProgramPanel];
	else if	([[session executables] count])	panel = [self programChooserPanel];
	else									panel = [self noProgramsPanel];

	[self setActivePanel: panel];
}

- (NSView *) activePanel
{
	return [[[self view] subviews] lastObject];
}

- (void) setActivePanel: (NSView *)panel
{
	[self willChangeValueForKey: @"activePanel"];

	for (NSView *subview in [[self view] subviews]) [subview removeFromSuperview];
	[[self view] addSubview: panel];
	
	[self didChangeValueForKey: @"activePanel"];
}

//Returns the display string used for the "open this program every time" checkbox toggle
- (NSString *) labelForToggle
{
	NSString *format = NSLocalizedString(
		@"Launch %@ every time I open this gamebox.",
		@"Label for default program checkbox in program panel. %@ is the lowercase filename of the currently-active program."
	);
	NSString *programPath = [[self representedObject] activeProgramPath];
	NSString *dosFilename = [[NSValueTransformer valueTransformerForName: @"BXDOSFilename"] transformedValue: programPath];
	
	return [NSString stringWithFormat: format, dosFilename, nil];
}

- (BOOL) activeProgramIsDefault
{
	NSString *defaultProgram	= [[[self representedObject] gamePackage] targetPath];
	NSString *activeProgram		= [[self representedObject] activeProgramPath];
	
	return [activeProgram isEqualToString: defaultProgram];
}

//Toggle whether or not the currently-active program should be the default program for this gamebox
- (void) setActiveProgramIsDefault: (BOOL) isDefault
{
	[self willChangeValueForKey: @"activeProgramIsDefault"];
	
	BXPackage *gamePackage	= [[self representedObject] gamePackage];
	NSString *activeProgram	= [[self representedObject] activeProgramPath];
	if (!gamePackage || !activeProgram) return;
	
	if (isDefault)							[gamePackage setTargetPath: activeProgram];
	else if ([self activeProgramIsDefault])	[gamePackage setTargetPath: nil];
	
	[self didChangeValueForKey: @"activeProgramIsDefault"];	
}
@end