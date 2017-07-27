# =============================================================================
# Allan CORNET - 2011
# Antoine ELIAS - 2013
# convert vcxproj of Visual Studio Solution to Intel, VS2012, VS2012
# =============================================================================
import re
import os
import shutil
import sys
import libxml2

# =============================================================================
flagConfigurationMakefile = "<ConfigurationType>Makefile</ConfigurationType>"
flagConfigurationApplication = "<ConfigurationType>Application</ConfigurationType>"
flagConfigurationDll = "<ConfigurationType>DynamicLibrary</ConfigurationType>"
flagConfigurationLib = "<ConfigurationType>StaticLibrary</ConfigurationType>"
#flagIntelCompiler = "Intel C++ Compiler XE 14.0"
flagVS2012Compiler = "v110"
flagVS2012XPCompiler = "v110_xp"
flagSubSystemConsole = 'Console'
flagSubSystemWindows = 'Windows'
flagVersionXP = '5.01'
flagVersionXP64 = '5.02'
flagVersion = ''
# =============================================================================
def usage():
    print('Usage: ICProjConvert120.py <sln_file> [-VC | -IC] [-q]\n')
    print('\n')
    print('Where:\n')
    print('sln_file  - is a path to solution file, which should be updated to specified\n')
    print('            project system.\n')
    print('-VC       - to use the Visual C++ project system.\n')
    print('-VC2012   - to use the Visual C++ 2012 project system.\n')
    print('-VC2012_xp   - to use the Visual C++ 2012 project system.\n')
    print('-IC       - to use the Intel C++ project system.\n')
    print('-q        - quiet mode, all information messages (except errors) are hidden.\n')
    print('-? or -h  - show help.    \n')
    print('\n')
# =============================================================================
def isSupportedByIntel(vcxprojFile):
    fileProject = open(vcxprojFile, 'rt')
    lines = fileProject.readlines()
    fileProject.close()
    for currentLine in lines:
        if currentLine.find(flagConfigurationApplication) > -1:
            return 1
        if currentLine.find(flagConfigurationDll) > -1:
            return 1
        if currentLine.find(flagConfigurationLib) > -1:
            return 1
        if currentLine.find(flagConfigurationMakefile) > -1:
            return 0
    return 0
# =============================================================================
def findIntelCompiler():
    #try all known env var
    if os.environ.get("ICPP_COMPILER15") <> None:
        return "Intel C++ Compiler XE 15.0"

    if os.environ.get("ICPP_COMPILER14") <> None:
        return "Intel C++ Compiler XE 14.0"

    if os.environ.get("ICPP_COMPILER13") <> None:
        return "Intel C++ Compiler XE 13.0"

    return None
# =============================================================================
def removeCompilerFlags(vcxprojFile):
    doc=libxml2.parseFile(vcxprojFile)
    context = doc.xpathNewContext()
    context.xpathRegisterNs("ms", "http://schemas.microsoft.com/developer/msbuild/2003")
    nodes=context.xpathEval('//ms:PropertyGroup/ms:PlatformToolset')

    if len(nodes)!=0:
        for n in nodes:
            n.unlinkNode()
    else:
        return 0;

    f=open(vcxprojFile,'w')
    doc.saveTo(f)
    f.close
    doc.freeDoc()
    return 1
# =============================================================================
def addVS2012Flags(vcxprojFile):
    addCompilerFlags(vcxprojFile, flagVS2012Compiler)
    addSubSystemFlags(vcxprojFile)
    addVersionFlags(vcxprojFile, flagVersion)
    return 1
# =============================================================================
def addIntelFlags(vcxprojFile):
    if vcxprojFile.find("graphic_export") == -1:
        flagIntelCompiler = findIntelCompiler();
        if flagIntelCompiler <> None:
            addCompilerFlags(vcxprojFile, flagIntelCompiler)
            return 1
        return 0
    return 1
# =============================================================================
def addXPFlags(vcxprojFile):
    flagIntelCompiler = findIntelCompiler();
    if flagIntelCompiler <> None:
        addCompilerFlags(vcxprojFile, flagIntelCompiler)
        addSubSystemFlags(vcxprojFile)
        addVersionFlags(vcxprojFile, flagVersionXP)
        return 1
    return 0
# =============================================================================
def addXP64Flags(vcxprojFile):
    flagIntelCompiler = findIntelCompiler();
    if flagIntelCompiler <> None:
        addCompilerFlags(vcxprojFile, flagIntelCompiler)
        addSubSystemFlags(vcxprojFile)
        addVersionFlags(vcxprojFile, flagVersionXP64)
        return 1
    return 0
# =============================================================================
def addSubSystemFlags(vcxprojFile):
    if vcxprojFile.find("SetupAtlas") != -1 or vcxprojFile.find("WScilex") != -1:
        addSubSystemFlag(vcxprojFile, flagSubSystemWindows)
    else:
        addSubSystemFlag(vcxprojFile, flagSubSystemConsole)
# =============================================================================
def addCompilerFlags(vcxprojFile, compilerFlag):
    doc=libxml2.parseFile(vcxprojFile)
    context = doc.xpathNewContext()
    context.xpathRegisterNs("ms", "http://schemas.microsoft.com/developer/msbuild/2003")
    nodes=context.xpathEval('//ms:PropertyGroup/ms:PlatformToolset')

    if len(nodes)!=0:
        for n in nodes:
            n.setContent(compilerFlag)
    else:
        nodes=context.xpathEval('//ms:PropertyGroup[@Label=\'Configuration\']')
        for n in nodes:
            newnode=libxml2.newNode('PlatformToolset')
            newnode.setContent(compilerFlag)
            n.addChild(newnode)

    f=open(vcxprojFile,'w')
    doc.saveTo(f)
    f.close
    doc.freeDoc()
    return 1
# =============================================================================
def addSubSystemFlag(vcxprojFile, subSystem):
    doc=libxml2.parseFile(vcxprojFile)
    context = doc.xpathNewContext()
    context.xpathRegisterNs("ms", "http://schemas.microsoft.com/developer/msbuild/2003")

    # update/add SubSystem property
    nodes=context.xpathEval('//ms:ItemDefinitionGroup/ms:Link/ms:SubSystem')

    if len(nodes)!=0:
        for n in nodes:
            n.setContent(subSystem)
    else:
        nodes=context.xpathEval('//ms:ItemDefinitionGroup/ms:Link')
        for n in nodes:
            newnode=libxml2.newNode('SubSystem')
            newnode.setContent(subSystem)
            n.addChild(newnode)

    f=open(vcxprojFile,'w')
    doc.saveTo(f)
    f.close
    doc.freeDoc()
    return 1
# =============================================================================
def addVersionFlags(vcxprojFile, version):
    doc=libxml2.parseFile(vcxprojFile)
    context = doc.xpathNewContext()
    context.xpathRegisterNs("ms", "http://schemas.microsoft.com/developer/msbuild/2003")

    # update/add MinimumRequiredVersion property
    nodes=context.xpathEval('//ms:ItemDefinitionGroup/ms:Link/ms:MinimumRequiredVersion')
    if len(nodes)!=0:
        for n in nodes:
            n.setContent(version)
    else:
        nodes=context.xpathEval('//ms:ItemDefinitionGroup/ms:Link')
        for n in nodes:
            newnode=libxml2.newNode('MinimumRequiredVersion')
            newnode.setContent(version)
            n.addChild(newnode)

    f=open(vcxprojFile,'w')
    doc.saveTo(f)
    f.close
    doc.freeDoc()
    return 1
# =============================================================================
def getProjectsFilenameFromSolution(solutionFilename):
    projectsFilename = []

    fileSolution = open(solutionFilename, 'rt')
    lines = fileSolution.readlines()
    fileSolution.close()

    pathProject = []
    for currentLine in lines:
        pathProject = []
        if currentLine.find(".vcxproj") > -1:
            ProjectSplittedArgs = currentLine.split()
            projectFilename = ProjectSplittedArgs[3]
            if projectFilename[0] == '\"':
                projectFilename = projectFilename[1:];
            if projectFilename[len(projectFilename)-1] == ',':
                projectFilename = projectFilename[:len(projectFilename)-1];
            if projectFilename[len(projectFilename)-1] == '\"':
                projectFilename = projectFilename[:len(projectFilename)-1];
            pathProject = os.path.abspath(os.path.dirname(solutionFilename) + os.sep + projectFilename)

        if pathProject != []:
            projectsFilename.append(pathProject)

    return projectsFilename
# =============================================================================
def main():
    if len(sys.argv) < 3:
        usage()
        sys.exit(2)

    if sys.argv[1] in ['/?', '/h' ,'-?', '-h', '--help']:
        usage()
        sys.exit(2)

    if not os.path.exists(os.path.abspath(sys.argv[1])):
        usage()
        print(os.path.abspath(sys.argv[1]) + " does not exist.", "\n")
        sys.exit(2)

    solutionFilename = os.path.abspath(sys.argv[1])
    conversionToIntel = 0
    conversionToVC = 0
    quietMode = 0

    for arg in sys.argv[2:]:
        if arg in ['-IC', '/IC']:
            print 'Convert to Intel'
            conversionToIntel = 1
        elif arg in ['-VC2012', '/VC2012']:
            print 'Convert to VS2012'
            conversionToVC = 2
        elif arg in ['-XP', '/XP']:
            print 'Convert to Intel for XP'
            conversionToVC = 3
        elif arg in ['-XP64', '/XP64']:
            print 'Convert to Intel for XP 64'
            conversionToVC = 4
        elif arg in ['-VC', '/VC']:
            print 'Convert to VS2010'
            conversionToVC = 1
        elif arg in ['/?', '/h' ,'-?', '-h', '--help']:
            usage()
            sys.exit(2)
        else:
            usage()
            print("option " + arg + " not recognized.", "\n")
            sys.exit(2)

    if conversionToVC == 1:
        if conversionToIntel == 1:
            usage()
            print("invalid argument(s).", "\n")
            sys.exit(2)

    projects = getProjectsFilenameFromSolution(solutionFilename)
    for thisProjectFilename in projects:
        path,file=os.path.split(thisProjectFilename)
        if isSupportedByIntel(thisProjectFilename) == 1:
            if conversionToIntel == 1:
                shutil.copyfile(thisProjectFilename, thisProjectFilename + '.old')
                addIntelFlags(thisProjectFilename)

            elif conversionToVC == 2:
                shutil.copyfile(thisProjectFilename, thisProjectFilename + '.old')
                if addVS2012Flags(thisProjectFilename) == 0:
                    print('Convert error : "' + thisProjectFilename + '"')
                    sys.exit(3)

            elif conversionToVC == 3:
                shutil.copyfile(thisProjectFilename, thisProjectFilename + '.old')
                if addXPFlags(thisProjectFilename) == 0:
                    print('Convert error : "' + thisProjectFilename + '"')
                    sys.exit(3)

            elif conversionToVC == 4:
                shutil.copyfile(thisProjectFilename, thisProjectFilename + '.old')
                if addXP64Flags(thisProjectFilename) == 0:
                    print('Convert error : "' + thisProjectFilename + '"')
                    sys.exit(3)

            elif conversionToVC == 1:
                shutil.copyfile(thisProjectFilename, thisProjectFilename + '.old')
                removeCompilerFlags(thisProjectFilename)
# =============================================================================
if __name__ == "__main__":
    main()
# =============================================================================
