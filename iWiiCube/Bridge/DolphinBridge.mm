// Copyright 2016 OatmealDome, WillCobb
// Licensed under GPLV2+
// Refer to the license.txt provided

#import "Bridge/DolphinBridge.h"

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

#include <cstdio>
#include <cstdlib>

#include "Common/CommonPaths.h"
#include "Common/CommonTypes.h"
#include "Common/CPUDetect.h"
#include "Common/Event.h"
#include "Common/FileUtil.h"
#include "Common/Logging/ConsoleListener.h"
#include "Common/Logging/LogManager.h"

#include "Core/BootManager.h"
#include "Core/ConfigManager.h"
#include "Core/Core.h"
#include "Core/Host.h"
#include "Core/State.h"
#include "Core/HW/Wiimote.h"
#include "Core/PowerPC/PowerPC.h"

#include "DiscIO/Filesystem.h"
#include "DiscIO/VolumeCreator.h"

#include "UICommon/UICommon.h"

#include "VideoCommon/OnScreenDisplay.h"
#include "VideoCommon/VideoBackendBase.h"

#include "Common/Logging/ConsoleListener.h"

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"


static CAEAGLLayer *renderLayer = nil;
//static CGLayer *renderLayer = nil;

#pragma mark - Host Calls

Common::Event updateMainFrameEvent;
void Host_Message(int Id)
{
    if (Id == WM_USER_JOB_DISPATCH) {
        dispatch_async(dispatch_get_main_queue(), ^{
            updateMainFrameEvent.Set();
            Core::HostDispatchJobs();
        });
    }
}

ConsoleListener::ConsoleListener()
{
}

ConsoleListener::~ConsoleListener()
{
}

void ConsoleListener::Log(LogTypes::LOG_LEVELS level, const char* text)
{
    switch (level)
    {
        case LogTypes::LOG_LEVELS::LDEBUG:
            printf("Debug: ");
            break;
        case LogTypes::LOG_LEVELS::LINFO:
            printf("Info: ");
            break;
        case LogTypes::LOG_LEVELS::LWARNING:
            printf("Warning: ");
            break;
        case LogTypes::LOG_LEVELS::LERROR:
            printf("Error: ");
            break;
        case LogTypes::LOG_LEVELS::LNOTICE:
            printf("Notice: ");
            break;
    }
    printf("%s\n", text);
}

void* Host_GetRenderHandle()
{
	//return ( void *)CFBridgingRetain(renderLayer);
	return (__bridge void *)renderLayer;
}

void Host_UpdateTitle(const std::string& title)
{
}

void Host_UpdateDisasmDialog()
{
}

void Host_UpdateMainFrame()
{
}

void Host_NotifyMapLoaded()
{
}

void Host_RefreshDSPDebuggerWindow()
{
}

void Host_RequestRenderWindowSize(int width, int height)
{
}

void Host_RequestFullscreen(bool enable_fullscreen)
{
}

void Host_SetStartupDebuggingParameters()
{
}

bool Host_UIHasFocus()
{
    return true;
}

bool Host_RendererHasFocus()
{
    return true;
}

bool Host_RendererIsFullscreen()
{
    return false;
}

void Host_ConnectWiimote(int wm_idx, bool connect)
{
}

void Host_SetWiiMoteConnectionState(int _State)
{
}

void Host_ShowVideoConfig(void*, const std::string&, const std::string&)
{
}

@implementation DolphinBridge : NSObject

- (id)init
{
    if (self = [super init]) {
        [self createUserFoldersAtPath:[AppDelegate libraryPath]];
        [self copyResourcesToPath:[AppDelegate documentsPath]];
        [self saveDefaultPreferences]; // Save every run until a settings ui is implemented.
    }
    return self;
}

- (void)openRomAtPath:(NSString* )path inLayer:(CAEAGLLayer *)layer
//- (void)openRomAtPath:(NSString* )path inLayer:(CGLayer *)layer
{
    renderLayer = layer;
    NSLog(@"Loading game at path: %@", path);
    UICommon::Init();
	//SConfig::GetInstance().m_FrameSkip = 12 ;
	//SConfig::GetInstance().m_FrameSkip = 3;
    //SConfig::GetInstance().m_FrameSkip = 9;
	SConfig::GetInstance().m_FrameSkip = 0;
	if (BootManager::BootCore([path UTF8String]))
		{
		NSLog(@"Booted Core");
	}
	else
		{
		NSLog(@"Unable to boot");
		return;
		}
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		while (!Core::IsRunning())
			{
			NSLog(@"Waiting for run");
			usleep(100000);
			}
		while (Core::IsRunning())
			{
			updateMainFrameEvent.Wait();
			Core::HostDispatchJobs();
			}
		UICommon::Shutdown();
	});
}

- (void)saveDefaultPreferences
{
	// Must use std::string when passing in strings to config
	// If you don't, the string will be passed as a bool and will always
	// Evaluate to true
	
	// Dolphin
	IniFile dolphinConfig;
	dolphinConfig.Load(File::GetUserPath(D_CONFIG_IDX) + "Dolphin.ini");
	//dolphinConfig.GetOrCreateSection("Core")->Set("CPUCore", PowerPC::CORE_JITARM64);
	dolphinConfig.GetOrCreateSection("Core")->Set("CPUCore", 4);
	dolphinConfig.GetOrCreateSection("Core")->Set("CPUThread", YES);
	dolphinConfig.GetOrCreateSection("Core")->Set("MMU", YES);
	
	///*
	dolphinConfig.GetOrCreateSection("Core")->Set("FastDiskSpeed", YES);
	dolphinConfig.GetOrCreateSection("Core")->Set("Fastmem", YES);
	//*/
	/*
	dolphinConfig.GetOrCreateSection("Core")->Set("FastDiskSpeed", NO);
	dolphinConfig.GetOrCreateSection("Core")->Set("Fastmem", NO);
	*/
	
	dolphinConfig.GetOrCreateSection("Core")->Set("GFXBackend", std::string("OGL"));
	dolphinConfig.GetOrCreateSection("Core")->Set("HLE_BS2", YES);
	dolphinConfig.GetOrCreateSection("Core")->Set("TimingVariance", 40);
	//dolphinConfig.GetOrCreateSection("Core")->Set("FrameSkip", 5); //Doesn't work?
	dolphinConfig.GetOrCreateSection("Core")->Set("FrameSkip", 0x00000000);
	dolphinConfig.GetOrCreateSection("Core")->Set("SyncGPU", NO);
	dolphinConfig.GetOrCreateSection("Core")->Set("SyncGPUMaxDistance", 200000);
	dolphinConfig.GetOrCreateSection("Core")->Set("SyncGPUMinDistance", -200000);
	dolphinConfig.GetOrCreateSection("Core")->Set("SyncGPUOverclock", 1.00000000);
	dolphinConfig.GetOrCreateSection("Core")->Set("FRFP", NO);
	dolphinConfig.GetOrCreateSection("Core")->Set("AccurateNaNs", NO);
	
	
	dolphinConfig.GetOrCreateSection("Core")->Set("SkipIdle", YES);
	dolphinConfig.GetOrCreateSection("Core")->Set("SyncOnSkipIdle", YES);
	dolphinConfig.GetOrCreateSection("Core")->Set("DSPHLE", YES);
	dolphinConfig.GetOrCreateSection("Core")->Set("EmulationSpeed", 1.00000000);
	dolphinConfig.GetOrCreateSection("Core")->Set("Overclock", 0.44999988);
	dolphinConfig.GetOrCreateSection("Core")->Set("OverclockEnabled", YES);
	dolphinConfig.GetOrCreateSection("Core")->Set("GPUDeterminismMode", std::string("Auto"));
	dolphinConfig.GetOrCreateSection("Core")->Set("OverrideGCLang", NO);
	
	
	dolphinConfig.GetOrCreateSection("Core")->Set("DefaultISO", std::string(""));
	dolphinConfig.GetOrCreateSection("Core")->Set("DVDRoot", std::string(""));
	dolphinConfig.GetOrCreateSection("Core")->Set("Apploader", std::string(""));
	dolphinConfig.GetOrCreateSection("Core")->Set("EnableCheats", NO);
	dolphinConfig.GetOrCreateSection("Core")->Set("SelectedLanguage", 0);
	dolphinConfig.GetOrCreateSection("Core")->Set("OverrideGCLang", NO);
	dolphinConfig.GetOrCreateSection("Core")->Set("DPL2Decoder", NO);
	dolphinConfig.GetOrCreateSection("Core")->Set("Latency", 2);
	dolphinConfig.GetOrCreateSection("Core")->Set("AGPCartAPath", std::string(""));
	dolphinConfig.GetOrCreateSection("Core")->Set("AGPCartBPath", std::string(""));
	dolphinConfig.GetOrCreateSection("Core")->Set("SlotA", 1);
	dolphinConfig.GetOrCreateSection("Core")->Set("SlotB", 255);
	dolphinConfig.GetOrCreateSection("Core")->Set("SerialPort1", 255);
	
	
	//Reset paths so Dolphin will search again
	dolphinConfig.GetOrCreateSection("Core")->Set("MemcardAPath", std::string(""));
	dolphinConfig.GetOrCreateSection("Core")->Set("MemcardBPath", std::string(""));
	
	int scale = [UIScreen mainScreen].scale;
	CGSize renderWindowSize = CGSizeMake(renderLayer.frame.size.width * scale, renderLayer.frame.size.height * scale);
	dolphinConfig.GetOrCreateSection("Display")->Set("FullscreenResolution", std::string("Auto"));
	//dolphinConfig.GetOrCreateSection("Display")->Set("Fullscreen", YES);
	dolphinConfig.GetOrCreateSection("Display")->Set("Fullscreen", NO);
	//dolphinConfig.GetOrCreateSection("Display")->Set("RenderWindowWidth", 640); //(int)renderWindowSize.width);
	//dolphinConfig.GetOrCreateSection("Display")->Set("RenderWindowWidth", (uint8_t)renderWindowSize.width);
	//dolphinConfig.GetOrCreateSection("Display")->Set("RenderWindowHeight", 480);//(int)renderWindowSize.height);
	//dolphinConfig.GetOrCreateSection("Display")->Set("RenderWindowHeight", (uint8_t)renderWindowSize.height);
	dolphinConfig.GetOrCreateSection("Display")->Set("RenderWindowWidth", 0);
	dolphinConfig.GetOrCreateSection("Display")->Set("RenderWindowHeight", 0);
	dolphinConfig.GetOrCreateSection("Display")->Set("RenderToMain", NO);
	dolphinConfig.GetOrCreateSection("Display")->Set("RenderWindowXPos", -1);
	dolphinConfig.GetOrCreateSection("Display")->Set("RenderWindowYPos", -1);
	dolphinConfig.GetOrCreateSection("Display")->Set("KeepWindowOnTop", NO);
	dolphinConfig.GetOrCreateSection("Display")->Set("ProgressiveScan", NO);
	dolphinConfig.GetOrCreateSection("Display")->Set("DisableScreenSaver", YES);
	/*
	dolphinConfig.GetOrCreateSection("Display")->Set("PAL60", YES);
	dolphinConfig.GetOrCreateSection("Display")->Set("ForceNTSCJ", NO);
	*/
	///*
	dolphinConfig.GetOrCreateSection("Display")->Set("PAL60", NO);
	dolphinConfig.GetOrCreateSection("Display")->Set("ForceNTSCJ", NO);
	//*/
	
	dolphinConfig.GetOrCreateSection("Movie")->Set("PauseMovie", NO);
	dolphinConfig.GetOrCreateSection("Movie")->Set("Author", std::string(""));
	dolphinConfig.GetOrCreateSection("Movie")->Set("DumpFrames", NO);
	dolphinConfig.GetOrCreateSection("Movie")->Set("DumpFramesSilent", NO);
	dolphinConfig.GetOrCreateSection("Movie")->Set("ShowInputDisplay", YES);
	
	dolphinConfig.GetOrCreateSection("DSP")->Set("EnableJIT", YES);
	dolphinConfig.GetOrCreateSection("DSP")->Set("DumpAudio", NO);
	dolphinConfig.GetOrCreateSection("DSP")->Set("DumpUCode", NO);
	dolphinConfig.GetOrCreateSection("DSP")->Set("Backend", std::string("CoreAudio"));
	dolphinConfig.GetOrCreateSection("DSP")->Set("Volume", 100);
	dolphinConfig.GetOrCreateSection("DSP")->Set("CaptureLog", NO);
	
	dolphinConfig.GetOrCreateSection("Input")->Set("BackgroundInput", NO);
	
	
	
	dolphinConfig.Save(File::GetUserPath(D_CONFIG_IDX) + "Dolphin.ini");

	
	
	
	//////////////////////////////////////////////////////////////////
	//
	// 		gfx_opengl.ini FILE SETTINGS
	//
	//////////////////////////////////////////////////////////////////
	

	
    // OpenGL
    IniFile oglConfig;
    oglConfig.Load(File::GetUserPath(D_CONFIG_IDX) + "gfx_opengl.ini");
	
	/*
	[Hardware]
	 VSync = True
	 Adapter = 0
	 */
	/*
	IniFile::Section* oglHardware = oglConfig.GetOrCreateSection("Hardware");
	oglHardware->Set("VSync", YES);
	oglHardware->Set("Adapter", 0);
	 */

	/*
	 [Settings]
	 AspectRatio = 0
	 Crop = False
	 wideScreenHack = False
	 UseXFB = False
	 UseRealXFB = False
	 SafeTextureCacheColorSamples = 0
	 ShowFPS = True
	 LogFPSToFile = False
	 ShowInputDisplay = False
	 OverlayStats = False
	 OverlayProjStats = False
	 DLOptimize = 0
	 Show = 0
	 DumpTextures = False
	 HiresTextures = False
	 DumpEFBTarget = False
	 DumpFrames = False
	 FreeLook = False
	 UseFFV1 = False
	 AnaglyphStereo = False
	 AnaglyphStereoSeparation = 200
	 AnaglyphFocalAngle = 0
	 EnablePixelLighting = False
	 HackedBufferUpload = False
	 FastDepthCalc = True
	 ShowEFBCopyRegions = False
	 MSAA = 3
	 EFBScale = 0
	 TexFmtOverlayEnable = False
	 TexFmtOverlayCenter = False
	 Wireframe = False
	 DstAlphaPass = False
	 DisableFog = False
	 EnableOpenCL = False
	 OMPDecoder = False
	 EnableShaderDebugging = False
	 LogRenderTimeToFile = False
	 BorderlessFullscreen = False
	 */
	
	
	
    IniFile::Section* oglSettings = oglConfig.GetOrCreateSection("Settings");
    oglSettings->Set("ShowFPS", YES);
	//oglSettings->Set("LogFPSToFile", NO);
	//oglSettings->Set("ShowInputDisplay", NO);
	oglSettings->Set("OverlayStats", YES);
	//oglSettings->Set("OverlayProjStats", NO);
	//oglSettings->Set("DLOptimize", 0);
	oglSettings->Set("DLOptimize", 1);
	//oglSettings->Set("Show", 0);
	//oglSettings->Set("DumpTextures", NO);
	//oglSettings->Set("HiresTextures", NO);
	//oglSettings->Set("DumpEFBTarget", NO);
	//oglSettings->Set("DumpFrames", YES);
	//oglSettings->Set("HackedBufferUpload", YES);
	//oglSettings->Set("FastDepthCalc", YES);
	
    oglSettings->Set("ExtendedFPSInfo", YES);
	oglSettings->Set("wideScreenHack", YES);
	oglSettings->Set("UseXFB", NO);
	//oglSettings->Set("UseRealXFB", NO);
	oglSettings->Set("SafeTextureCacheColorSamples", 128);
	//oglSettings->Set("EnableShaderDebugging", NO);
	//oglSettings->Set("UseFFV1", NO);
	oglSettings->Set("CacheHiresTextures", YES);
	//oglSettings->Set("SSAA", NO);
	//oglSettings->Set("ConvertHiresTexture", YES);
    //oglSettings->Set("EFBScale", 2);
	oglSettings->Set("EFBScale", 2);
	//oglSettings->Set("EFBScale", 0);
	//oglSettings->Set("EFBScale", 1);
	//oglSettings->Set("LogRenderTimeToFile", NO);
	//oglSettings->Set("BorderlessFFullscreen", NO);
    oglSettings->Set("MSAA", 0);
	
    oglSettings->Set("EnablePixelLighting", YES);
	//oglSettings->Set("EnablePixelLighting", NO);
	//oglSettings->Set("EnablePerPixelDepth", NO);
    //oglSettings->Set("DisableFog", YES);
	oglSettings->Set("DisableFog", NO);

    IniFile::Section* oglEnhancements = oglConfig.GetOrCreateSection("Enhancements");
    oglEnhancements->Set("MaxAnisotropy", 0);
	oglEnhancements->Set("PostProcessingShader", std::string(""));
	//oglEnhancements->Set("Enable3dVision", NO);
	//oglEnhancements->Set("ForceFiltering", NO);
	oglEnhancements->Set("ForceFiltering", YES);
    oglEnhancements->Set("StereoSwapEyes", NO);
    oglEnhancements->Set("StereoMode", 0);
    //oglEnhancements->Set("StereoDepth", 20);
	oglEnhancements->Set("StereoDepth", 20);
    oglEnhancements->Set("StereoConvergence", 20);
	
	
    IniFile::Section* oglHacks = oglConfig.GetOrCreateSection("Hacks");
	///*
	//oglHacks->Set("EFBScaledCopy", NO);
	oglHacks->Set("EFBScaledCopy", YES);
	oglHacks->Set("EFBAccessEnable", NO);
	oglHacks->Set("EFBEmulateFormatChanges", NO);
	//oglHacks->Set("EFBEmulateFormatChanges", YES);
    oglHacks->Set("EFBCopyEnable", NO);
    oglHacks->Set("EFBToTextureEnable", NO);
	oglHacks->Set("EFBCopyCacheEnable", YES);
	//oglHacks->Set("DlistCachingEnabled", YES);
	// /
    oglConfig.Save(File::GetUserPath(D_CONFIG_IDX) + "gfx_opengl.ini");

    // Move Controller Settings
    NSString *configPath = [NSString stringWithCString:File::GetUserPath(D_CONFIG_IDX).c_str()
							encoding:NSUTF8StringEncoding];
    [self copyBundleDirectoryOrFile:@"Config/GCPadNew.ini" toPath:[configPath stringByAppendingPathComponent:@"GCPadNew.ini"]];
    [self copyBundleDirectoryOrFile:@"Config/WiimoteNew.ini" toPath:[configPath stringByAppendingPathComponent:@"WiimoteNew.ini.ini"]];
	
	
	
	
/////////////////////
//
//
//		ORIGINAL SETTINGS!!!
//
//
// // Dolphin
//	IniFile dolphinConfig;
//	dolphinConfig.Load(File::GetUserPath(D_CONFIG_IDX) + "Dolphin.ini");
//	dolphinConfig.GetOrCreateSection("Core")->Set("CPUCore", PowerPC::CORE_JITARM64);
//	dolphinConfig.GetOrCreateSection("Core")->Set("CPUThread", YES);
//	dolphinConfig.GetOrCreateSection("Core")->Set("Fastmem", NO);
//	dolphinConfig.GetOrCreateSection("Core")->Set("GFXBackend", std::string("OGL"));
//	dolphinConfig.GetOrCreateSection("Core")->Set("FrameSkip", 5); //Doesn't work?
//
//	//Reset paths so Dolphin will search again
//	dolphinConfig.GetOrCreateSection("Core")->Set("MemcardAPath", std::string(""));
//	dolphinConfig.GetOrCreateSection("Core")->Set("MemcardBPath", std::string(""));
//
//	int scale = [UIScreen mainScreen].scale;
//	CGSize renderWindowSize = CGSizeMake(renderLayer.frame.size.width * scale, renderLayer.frame.size.height * scale);
//	dolphinConfig.GetOrCreateSection("Display")->Set("RenderWindowWidth", (int)renderWindowSize.width);
//	dolphinConfig.GetOrCreateSection("Display")->Set("RenderWindowHeight", (int)renderWindowSize.height);
//	dolphinConfig.Save(File::GetUserPath(D_CONFIG_IDX) + "Dolphin.ini");
//
//	// OpenGL
//	IniFile oglConfig;
//	oglConfig.Load(File::GetUserPath(D_CONFIG_IDX) + "gfx_opengl.ini");
//
//	IniFile::Section* oglSettings = oglConfig.GetOrCreateSection("Settings");
//	oglSettings->Set("ShowFPS", YES);
//	oglSettings->Set("ExtendedFPSInfo", YES);
//	oglSettings->Set("EFBScale", 2);
//	oglSettings->Set("MSAA", 0);
//	oglSettings->Set("EnablePixelLighting", YES);
//	oglSettings->Set("DisableFog", NO);
//
//	IniFile::Section* oglEnhancements = oglConfig.GetOrCreateSection("Enhancements");
//	oglEnhancements->Set("MaxAnisotropy", 0);
//	oglEnhancements->Set("ForceFiltering", YES);
//	oglEnhancements->Set("StereoSwapEyes", NO);
//	oglEnhancements->Set("StereoMode", 0);
//	oglEnhancements->Set("StereoDepth", 20);
//	oglEnhancements->Set("StereoConvergence", 20);
//
//	IniFile::Section* oglHacks = oglConfig.GetOrCreateSection("Hacks");
//	oglHacks->Set("EFBScaledCopy", YES);
//	oglHacks->Set("EFBAccessEnable", NO);
//	oglHacks->Set("EFBEmulateFormatChanges", NO);
//	oglHacks->Set("EFBCopyEnable", NO);
//	oglHacks->Set("EFBToTextureEnable", YES);
//	oglHacks->Set("EFBCopyCacheEnable", YES);
//
//	oglConfig.Save(File::GetUserPath(D_CONFIG_IDX) + "gfx_opengl.ini");
//
//	// Move Controller Settings
//	NSString *configPath = [NSString stringWithCString:File::GetUserPath(D_CONFIG_IDX).c_str()
//											  encoding:NSUTF8StringEncoding];
//	[self copyBundleDirectoryOrFile:@"Config/GCPadNew.ini" toPath:[configPath stringByAppendingPathComponent:@"GCPadNew.ini"]];
//	[self copyBundleDirectoryOrFile:@"Config/WiimoteNew.ini" toPath:[configPath stringByAppendingPathComponent:@"WiimoteNew.ini.ini"]];


}

-(void)copyResourcesToPath:(NSString*)resourcesPath
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath: [resourcesPath stringByAppendingString:@"GC"]])
    {
        NSLog(@"Copying GC folder...");
        [self copyBundleDirectoryOrFile:@"GC" toPath:resourcesPath];
    }
    if (![fileManager fileExistsAtPath: [resourcesPath stringByAppendingString:@"Shaders"]])
    {
        NSLog(@"Copying Shaders folder...");
        [self copyBundleDirectoryOrFile:@"Shaders" toPath:resourcesPath];
    }
}

- (void)copyBundleDirectoryOrFile:(NSString* )file toPath:(NSString*)destination
{
    NSString* source = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/"] stringByAppendingString:file];
    NSLog(@"copyDirectory source: %@", source);
    NSError* err = nil;
    if (![[NSFileManager defaultManager] copyItemAtPath:source toPath:destination error:&err])
    {
        NSLog(@"Error copying directory: %@", [err localizedDescription]);
    }
}

- (void)createUserFoldersAtPath:(NSString*)path
{
    std::string directory([path cStringUsingEncoding:NSUTF8StringEncoding]);
    UICommon::SetUserDirectory(directory);
    UICommon::CreateDirectories();
}

@end

#pragma GCC diagnostic pop
