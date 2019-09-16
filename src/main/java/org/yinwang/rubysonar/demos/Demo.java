package org.yinwang.rubysonar.demos;

import org.jetbrains.annotations.NotNull;
import org.yinwang.rubysonar.Analyzer;
import org.yinwang.rubysonar.Options;
import org.yinwang.rubysonar.Progress;
import org.yinwang.rubysonar.Utils;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;


public class Demo {

    private static File OUTPUT_DIR;

    private static final String CSS = Utils.readResource("org/yinwang/rubysonar/css/demo.css");
    private static final String JS = Utils.readResource("org/yinwang/rubysonar/javascript/highlight.js");
    private static final String JS_DEBUG = Utils.readResource("org/yinwang/rubysonar/javascript/highlight-debug.js");

    private Analyzer analyzer;
    private String rootPath;
    private Linker linker;


    private void makeOutputDir() {
        if (!OUTPUT_DIR.exists()) {
            OUTPUT_DIR.mkdirs();
            Utils.msg("Created directory: " + OUTPUT_DIR.getAbsolutePath());
        }
    }


    private void start(@NotNull String fileOrDir, Map<String, Object> options) throws Exception {
        File f = new File(fileOrDir);
        File rootDir = f.isFile() ? f.getParentFile() : f;
        try {
            rootPath = Utils.unifyPath(rootDir);
        } catch (Exception e) {
            Utils.die("File not found: " + f);
        }

        analyzer = new Analyzer(options);
        Utils.msg("Loading and analyzing files");
        analyzer.analyze(f.getPath());
        analyzer.finish();

        generateHtml();
        analyzer.close();
    }


    private void generateHtml() {
        Utils.msg("\nGenerating HTML");
        makeOutputDir();

        linker = new Linker(rootPath, OUTPUT_DIR);
        linker.findLinks(analyzer);

        int rootLength = rootPath.length();

        int total = 0;
        for (String path : analyzer.getLoadedFiles()) {
            if (path.startsWith(rootPath)) {
                total++;
            }
        }

        Utils.msg("\nWriting HTML");
        Progress progress = new Progress(total, 50);

        for (String path : analyzer.getLoadedFiles()) {
            if (path.startsWith(rootPath)) {
                progress.tick();
                File destFile = Utils.joinPath(OUTPUT_DIR, path.substring(rootLength));
                destFile.getParentFile().mkdirs();
                String destPath = destFile.getAbsolutePath() + ".html";
                String html = markup(path);
                try {
                    Utils.writeFile(destPath, html);
                } catch (Exception e) {
                    Utils.msg("Failed to write: " + destPath);
                }
            }
        }

        Utils.msg("\nWrote " + analyzer.getLoadedFiles().size() + " files to " + OUTPUT_DIR);
    }


    @NotNull
    private String markup(String path) {
        String source;

        try {
            source = Utils.readFile(path);
        } catch (Exception e) {
            Utils.die("Failed to read file: " + path);
            return "";
        }

        List<Style> styles = new ArrayList<>();
        styles.addAll(linker.getStyles(path));

        String styledSource = new StyleApplier(path, source, styles).apply();
//        String outline = new HtmlOutline(analyzer).generate(path);

        StringBuilder sb = new StringBuilder();
        sb.append("<html><head title=\"")
                .append(path)
                .append("\">")

                .append("<style type='text/css'>\n")
                .append(CSS)
                .append("</style>\n")

                .append("<script language=\"JavaScript\" type=\"text/javascript\">\n")
                .append(Analyzer.self.hasOption("debug") ? JS_DEBUG : JS)
                .append("</script>\n")

                .append("</head>\n<body>\n")

                .append("<pre>")
                .append(addLineNumbers(styledSource))
                .append("</pre>")

                .append("</body></html>");
        return sb.toString();
    }


    @NotNull
    private String addLineNumbers(@NotNull String source) {
        StringBuilder result = new StringBuilder((int) (source.length() * 1.2));
        int count = 1;
        for (String line : source.split("\n")) {
            result.append("<span class='lineno'>");
            result.append(String.format("%1$4d", count++));
            result.append("</span> ");
            result.append(line);
            result.append("\n");
        }
        return result.toString();
    }


    private static void usage() {
        Utils.msg("Usage:  java -jar rubysonar-2.0-SNAPSHOT.jar <file-or-dir> <output-dir>");
        Utils.msg("Example that generates an index for Python 2.7 standard library:");
        Utils.msg(" java -jar rubysonar-2.0-SNAPSHOT.jar /usr/lib/python2.7 ./html");
        System.exit(0);
    }


    @NotNull
    private static File checkFile(String path) {
        File f = new File(path);
        if (!f.canRead()) {
            Utils.die("Path not found or not readable: " + path);
        }
        return f;
    }


    public static void main(@NotNull String[] args) throws Exception {
        Options options = new Options(args);
        List<String> argList = options.getArgs();
        String fileOrDir = argList.get(0);
        OUTPUT_DIR = new File(argList.get(1));

        new Demo().start(fileOrDir, options.getOptionsMap());
        Utils.msg(Utils.getGCStats());
    }
}
