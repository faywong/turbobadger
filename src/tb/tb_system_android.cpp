// ================================================================================
// ==      This file is a part of Turbo Badger. (C) 2011-2014, Emil Segerås      ==
// ==                     See tb_core.h for more information.                    ==
// ================================================================================

#include "tb_system.h"

#ifdef TB_SYSTEM_ANDROID
#ifndef TB_BACKEND_SDL2

#include "tb_debug.h"
#include "tb_str.h"

#include <android/log.h>
#include <sys/time.h>
#include <stdio.h>

// for native asset manager
#include <sys/types.h>
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <android/configuration.h>

#if defined(TB_RUNTIME_DEBUG_INFO)

#define  LOG_TAG    "TB"
#define  LOGI(...)  __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define  LOGE(...)  __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

void TBDebugOut(const tb::TBStr & str)
{
	LOGI("%s", str.CStr());
}

#endif // TB_RUNTIME_DEBUG_INFO

AAssetManager *g_pManager;

void SetAssetManager(AAssetManager *pManager)
{
	g_pManager = pManager;
}

namespace tb {

// == TBSystem ========================================

double TBSystem::GetTimeMS()
{
	struct timeval now;
	gettimeofday(&now, NULL);
	return now.tv_usec / 1000 + now.tv_sec * 1000;
}

void TBSystem::RescheduleTimer(double fire_time)
{
}

int TBSystem::GetLongClickDelayMS()
{
	return 500;
}

int TBSystem::GetPanThreshold()
{
	return 5 * GetDPI() / 120;
}

int TBSystem::GetPixelsPerLine()
{
	return 40 * GetDPI() / 120;
}

int TBSystem::GetDPI()
{
	AConfiguration *config = AConfiguration_new();
	AConfiguration_fromAssetManager(config, g_pManager);
	int32_t density = AConfiguration_getDensity(config);
	AConfiguration_delete(config);
	if (density == 0 || density == ACONFIGURATION_DENSITY_NONE)
		return 120;
	return density;
}

} // namespace tb

#endif // !TB_SYSTEM_SDL2
#endif // TB_SYSTEM_ANDROID
