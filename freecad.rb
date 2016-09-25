require "formula"

class Freecad < Formula
  homepage "http://sourceforge.net/projects/free-cad/"
  head "git://git.code.sf.net/p/free-cad/code"
  url "http://downloads.sourceforge.net/project/free-cad/FreeCAD%20Source/freecad_0.15.4671.tar.gz"
  sha256 "8dda8f355cb59866a55c9c6096f39a3ebc5347892284db4c305352cc9be03bbc"

  # Debugging Support
  option 'with-debug', 'Enable debugging build'

  # Should work with OCE (OpenCascade Community Edition) or Open Cascade
  # OCE is the prefered option
  option 'with-opencascade', 'Build with OpenCascade'

  # Build without external pivy (use old bundled version)
  option 'without-external-pivy', 'Build without external Pivy (use old bundled version)'

  occ_options = []
  if MacOS.version < 10.7
    occ_options = ['--without-tbb']
  end
  
  if build.with? 'opencascade'
    depends_on 'opencascade' => occ_options
  else
    depends_on 'oce' => occ_options
  end

  # Build dependencies
  depends_on 'doxygen' => :build
  depends_on 'cmake' => :build
  depends_on :fortran => :build

  # Required dependencies
  depends_on 'boost'
  depends_on 'sip'
  depends_on 'xerces-c'
  depends_on 'eigen'
  depends_on 'coin' => ['--without-framework', '--without-soqt']
  depends_on 'qt'
  depends_on 'pyqt'
  depends_on 'shiboken'
  depends_on 'pyside'
  depends_on 'pyside-tools'
  depends_on 'python'
  depends_on 'orocos-kdl'

  # Recommended dependencies
  depends_on 'freetype' => :recommended

  # Allow building with internal pivy
  unless build.without? 'external-pivy'
    depends_on 'pivy' => [:recommended, '--HEAD']
  end

  # Optional Dependencies
  depends_on :x11 => :optional

  def install
    if build.with? 'debug'
      ohai "Creating debugging build..."
    end

    # Allow building with internal pivy
    use_external_pivy='ON'
    if build.without? 'external-pivy'
      ohai "Building without external Pivy"
      use_external_pivy='OFF'
    end

    # Enable Fortran
    libgfortran = `$FC --print-file-name libgfortran.a`.chomp
    ENV.append 'LDFLAGS', "-L#{File.dirname libgfortran} -lgfortran"

    # Brewed python include and lib info
    # TODO: Don't hardcode bin path
    python_prefix = `/usr/local/bin/python-config --prefix`.strip
    python_library = "#{python_prefix}/Python"
    python_include_dir = "#{python_prefix}/Headers"

    # Find OCE cmake file location
    # TODO add opencascade support/detection
    oce_dir = "#{Formula['oce'].opt_prefix}/OCE.framework/Versions/#{Formula['oce'].version}/Resources"

    # Set up needed cmake args
    args = std_cmake_args + %W[
      -DFREECAD_USE_EXTERNAL_PIVY=#{use_external_pivy}
      -DFREECAD_USE_EXTERNAL_KDL=ON
      -DPYTHON_LIBRARY=#{python_library}
      -DPYTHON_INCLUDE_DIR=#{python_include_dir}
      -DOCE_DIR=#{oce_dir}
      -DFREETYPE_INCLUDE_DIRS=#{Formula.factory('freetype').opt_prefix}/include/freetype2/
    ]

    if build.with? 'debug'
      # Create debugging build and tack on the build directory
      args << '-DCMAKE_BUILD_TYPE=Debug' << '.'
    
      system "cmake", *args
      system "make", "install"
    else
      # Create standard build and tack on the build directory
      args << '.'
    
      system "cmake", *args
      system "make", "install/strip"
    end
  end

  def caveats; <<-EOS.undent
    After installing FreeCAD you may want to do the following:

    1. Amend your PYTHONPATH environmental variable to point to
       the FreeCAD directory
         export PYTHONPATH=#{bin}:$PYTHONPATH
    EOS
  end
end
