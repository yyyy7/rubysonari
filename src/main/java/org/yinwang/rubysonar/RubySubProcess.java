package org.yinwang.rubysonar;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import java.io.File;
import java.io.FileWriter;
import java.io.InputStream;
import java.io.OutputStreamWriter;

public class RubySubProcess {
    private Process rubyProcess;
    private static final String DUMP_RUBY_RESOURCE = "org/yinwang/rubysonar/ruby/dump_ruby.rb";
    private static final String RUBY_EXE = "irb";
    private String jsonizer;
    private String parserLog;

    public RubySubProcess() {
        String sid = Utils.newSessionId();
        jsonizer = Utils.locateTmp("dump_ruby", sid);
        parserLog = Utils.locateTmp("parser_log", sid);
    }

    static public RubySubProcess newInstance() {
        RubySubProcess p = new RubySubProcess();
        p.startInterpreter(RUBY_EXE);
        return p;
    }


    @Nullable
    private void startInterpreter(String interpExe) {
        String jsonizeStr = "";
        Process p = null;

        try {
            InputStream jsonize =
                    Thread.currentThread()
                            .getContextClassLoader()
                            .getResourceAsStream(DUMP_RUBY_RESOURCE);
            jsonizeStr = Utils.readWholeStream(jsonize);
        } catch (Exception e) {
            Utils.die("Failed to open resource file:" + DUMP_RUBY_RESOURCE);
        }

        try {
            FileWriter fw = new FileWriter(jsonizer);
            fw.write(jsonizeStr);
            fw.close();
        } catch (Exception e) {
            Utils.die("Failed to write into: " + jsonizer);
        }

        ProcessBuilder builder = new ProcessBuilder();
        if (getCurrentOS().contains("win")) {
            builder.command("cmd.exe", "/c", interpExe);
        } else {
            builder.command(interpExe);
        }

        builder.redirectErrorStream(true);
        builder.redirectError(new File(parserLog));
        builder.redirectOutput(new File(parserLog));
        try {
            builder.environment().remove("RUBYLIB");
            p = builder.start();
        } catch (Exception e) {
            Utils.msg(e.getMessage());
            Utils.die("Failed to start irb");
        }

        if (!sendCommand("load '" + jsonizer + "'", p)) {
            p.destroy();
            Utils.die("Failed to load jsonizer, please report bug");
        }
        rubyProcess = p;
    }

    boolean sendCommand(String cmd, @NotNull Process rubyProcess) {
        try {
            OutputStreamWriter writer = new OutputStreamWriter(rubyProcess.getOutputStream());
            writer.write(cmd);
            writer.write("\n");
            writer.flush();
            return true;
        } catch (Exception e) {
            Utils.msg("\nFailed to send command to Ruby interpreter: " + cmd);
            return false;
        }
    }

    boolean sendCommand(String cmd) {
        return sendCommand(cmd, rubyProcess);
    }

    /**
     * if ru by process exists, then destroy it
     */
    void tryDestroyProcess() {
        if (rubyProcess != null) {
            rubyProcess.destroy();
            Utils.testmsg("destroy irb");
        }
    }

    private String getCurrentOS() {
        return System.getProperty("os.name").toLowerCase();
    }
}
