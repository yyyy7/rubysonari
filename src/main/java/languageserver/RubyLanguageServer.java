package languageserver;

import org.eclipse.lsp4j.*;
import org.eclipse.lsp4j.jsonrpc.messages.Either;
import org.eclipse.lsp4j.services.LanguageServer;
import org.eclipse.lsp4j.services.LanguageClient;
import org.eclipse.lsp4j.services.LanguageClientAware;
import org.eclipse.lsp4j.services.TextDocumentService;
import org.eclipse.lsp4j.services.WorkspaceService;
import org.yinwang.rubysonar.Analyzer;
import org.yinwang.rubysonar.Binding;
import org.yinwang.rubysonar._;
import org.yinwang.rubysonar.ast.Node;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.concurrent.CompletableFuture;

class RubyLanguageServer implements LanguageServer, LanguageClientAware {
  private LanguageClient client = null;
  public static Map<String, List<Map<String, Object>>> positions;
  // @SuppressWarnings("unused")
  private String workspaceRoot = null;

  private Analyzer analyzer;

  @Override
  public CompletableFuture<InitializeResult> initialize(InitializeParams params) {
    _.msg(params.toString());
    workspaceRoot = params.getRootUri();
    if (workspaceRoot == null || workspaceRoot == "") {
      _.die("got null workspaceRoot");
    }

    Map<String, Object> options = new HashMap<>();
    positions = new LinkedHashMap<>();
    analyzer = new Analyzer(options);
    analyzer.analyze(workspaceRoot.substring(7));
    generateRefs();

    ServerCapabilities capabilities = new ServerCapabilities();
    capabilities.setDefinitionProvider(true);
    capabilities.setHoverProvider(true);

    return CompletableFuture.completedFuture(new InitializeResult(capabilities));
  }

  public void generateRefs() {

    for (Map.Entry<Node, List<Binding>> e : analyzer.references.entrySet()) {

      Node node = e.getKey();
      String file = node.file;

      if (file != null && file.startsWith(Analyzer.self.projectDir)) {
        file = _.projRelPath(file);

        String positionKey = file + "-" + node.line + "-" + node.col;

        List<Map<String, Object>> dests = new ArrayList<>();
        for (Binding b : e.getValue()) {
          String destFile = b.file;
          if (destFile != null && destFile.startsWith(Analyzer.self.projectDir)) {
            destFile = _.projRelPath(destFile);
            Map<String, Object> dest = new LinkedHashMap<>();
            dest.put("name", b.node.name);
            dest.put("file", destFile);
            dest.put("start", b.start);
            dest.put("end", b.end);
            dest.put("line", b.node.line);
            dest.put("col", b.node.col);
            dests.add(dest);
            _.msg("dests: " + b.node.name + destFile + b.node.line + b.node.col);
          }
        }
        if (!dests.isEmpty()) {
          positions.put(positionKey, dests);
        }
      }
    }
  }

  @Override
  public CompletableFuture<Object> shutdown() {
    return CompletableFuture.completedFuture(null);
  }

  @Override
  public void exit() {
  }

  @Override
  public void connect(LanguageClient client) {
    this.client = client;
  }

  private FullTextDocumentService fullTextDocumentService = new FullTextDocumentService() {

    @Override
    public CompletableFuture<List<? extends Location>> definition(TextDocumentPositionParams position) {
      String uri = position.getTextDocument().getUri();
      String[] uriSplit = uri.split("/");
      String file = uriSplit[uriSplit.length-1];
      int line = position.getPosition().getLine()+1;
      int col = position.getPosition().getCharacter()+1;
      String positionKey = file + "-" + line + "-" + col;
      for (Entry<String, List<Map<String, Object>>> e : RubyLanguageServer.positions.entrySet()) {
        _.msg("------Key: "+ e.getKey());
        Map<String, Object> value = e.getValue().get(0);
        _.msg("------Value: " + value.get("name") + " " + value.get("file") + " " + value.get("line") + " " + value.get("col"));
      }
        List<Map<String, Object>> dests = RubyLanguageServer.positions.get(positionKey);
        _.msg("======");
        _.msg(positionKey);
        Range r;  
        if (dests == null) {
            r = new Range();
        } else {
            int targetLine = (int)dests.get(0).get("line") - 1;
            int targetCol = (int)dests.get(0).get("col")-1;
            r = new Range(new Position(targetLine, targetCol), new Position(targetLine, targetCol+1));
        }
        return CompletableFuture.completedFuture(Arrays.asList(new Location("file://" +Analyzer.self.projectDir + "/"+ file, r)));
    }
  };

  @Override
  public TextDocumentService getTextDocumentService() {
    return fullTextDocumentService;

  }

  private int maxNumberOfProblems = 100;

  @Override
  public WorkspaceService getWorkspaceService() {
    return new WorkspaceService() {
      @Override
      public CompletableFuture<List<? extends SymbolInformation>> symbol(WorkspaceSymbolParams params) {
          return null;
      }

      @Override
      public void didChangeConfiguration(DidChangeConfigurationParams params) {
          Map<String, Object> settings = (Map<String, Object>) params.getSettings();
          Map<String, Object> languageServerExample = (Map<String, Object>) settings.get("languageServerExample");
          maxNumberOfProblems = ((Double)languageServerExample.getOrDefault("maxNumberOfProblems", 100.0)).intValue();
          fullTextDocumentService.documents.values().forEach(d -> validateDocument(d));
      }

      @Override
      public void didChangeWatchedFiles(DidChangeWatchedFilesParams params) {
          client.logMessage(new MessageParams(MessageType.Log, "We received an file change event"));
      }
  };
  }

  private void validateDocument(TextDocumentItem document) {
    List<Diagnostic> diagnostics = new ArrayList<>();
    String[] lines = document.getText().split("\\r?\\n");
    int problems = 0;
    for (int i = 0; i < lines.length && problems < maxNumberOfProblems; i++) {
        String line = lines[i];
        int index = line.indexOf("typescript");
        if (index >= 0) {
            problems++;
            Diagnostic diagnostic = new Diagnostic();
            diagnostic.setSeverity(DiagnosticSeverity.Warning);
            diagnostic.setRange(new Range(new Position(i, index), new Position(i, index + 10)));
            diagnostic.setMessage(String.format("%s should be spelled TypeScript", line.substring(index, index + 10)));
            diagnostic.setSource("ex");
            diagnostics.add(diagnostic);
        }
    }

    client.publishDiagnostics(new PublishDiagnosticsParams(document.getUri(), diagnostics));
  }
}