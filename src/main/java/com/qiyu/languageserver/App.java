package com.qiyu.languageserver;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Socket;

import org.eclipse.lsp4j.jsonrpc.Launcher;
import org.eclipse.lsp4j.launch.LSPLauncher;
import org.eclipse.lsp4j.services.LanguageClient;

public class App {
  
  public static void main(String[] args) {
    String port = args[0];

    try {
      Socket socket = new Socket("localhost", Integer.parseInt(port));
      InputStream in = socket.getInputStream();
      OutputStream out = socket.getOutputStream();

      RubyLanguageServer server = new RubyLanguageServer();
      Launcher<LanguageClient> launcher = LSPLauncher.createServerLauncher(server, in, out);

      LanguageClient client = launcher.getRemoteProxy();
      server.connect(client);

      launcher.startListening();
    } catch (IOException e) {
      System.out.println(e.getMessage());
    }
  }
}