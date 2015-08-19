package org.clide.clide;

import javax.tools.JavaCompiler;

public class JprCompiler {

    public static void main( String[] args ) {
        final JavaCompiler javac = ToolProvider.getSystemJavaCompiler();
           DiagnosticCollector<JavaFileObject> diagnostics =
       new DiagnosticCollector<JavaFileObject>();
   StandardJavaFileManager fm = compiler.getStandardFileManager(diagnostics, null, null);
    }
}
