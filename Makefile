
all: glfw sdl2 em em-glfw

glfw:
	[ -d BuildGLFW ] || ./build.sh -glfw -gl
	cd BuildGLFW && $(MAKE)

sdl2:
	[ -d BuildSDL2 ] || ./build.sh -sdl2 -gl3
	cd BuildSDL2 && $(MAKE)

em:
	[ -d BuildEmsc ] || ./build.sh -gles2 -sdl2 -em
	cd BuildEmsc && $(MAKE)

em-glfw:
	[ -d BuildEmscGl ] || ./build.sh -gles2 -glfw -em -o BuildEmscGl
	cd BuildEmscGl && $(MAKE)

xc:
	[ -d Build-Xcode ] || \
		(cmake . -G Xcode -BBuild-Xcode -DTB_RENDERER_GL3=ON -DTB_BUILD_DEMO_SDL2=ON || rm -rf Build-Xcode)
	cd Build-Xcode && xcrun xcodebuild -project "turbobadger.xcodeproj" -target TurboBadgerDemoSDL

ios:
	[ -d Build-iOS ] || (cmake . -G Xcode -BBuild-iOS -DTB_RENDERER_GLES_2=ON || rm -rf Build-iOS)
	cd Build-iOS   && xcrun xcodebuild -project "turbobadger.xcodeproj" -target ?

lib:
	[ -d BuildLib ] || ./build.sh -o BuildLib -gl3
	cd BuildLib && $(MAKE)

and:
	cd DemoAndroid2 && ./gradlew build
	#cd DemoAndroid && ninja

distclean:
	rm -rf Build*

#%:
#	cd Build && $(MAKE) $@
#
