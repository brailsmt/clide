package org.clide;

import javax.tools.JavaCompiler;
import javax.tools.JavaFileObject;
import javax.tools.StandardJavaFileManager;
import javax.tools.ToolProvider;
import java.util.Arrays;

import com.sun.tools.javac.resources.javac;

public class ClideJavac {
    static JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();

    public static void main(String ... args) {
        StandardJavaFileManager fileManager = compiler.getStandardFileManager(null, null, null);
        fileManager.getJavaFileObjects();
    }

//    private static Class<?> compile(String className, String sourceCodeInText) throws Exception {
//        SourceCode sourceCode = new SourceCode(className, sourceCodeInText);
//        CompiledCode compiledCode = new CompiledCode(className);
//        Iterable<? extends JavaFileObject> compilationUnits = Arrays.asList(sourceCode);
//        DynamicClassLoader cl = new DynamicClassLoader(ClassLoader.getSystemClassLoader());
//        ExtendedStandardJavaFileManager fileManager = new ExtendedStandardJavaFileManager(
//                javac.getStandardFileManager(null, null, null), compiledCode, cl);
//        JavaCompiler.CompilationTask task = javac.getTask(null, fileManager, null, null, null, compilationUnits);
//        boolean result = task.call();
//        return cl.loadClass(className);
//    }
}
