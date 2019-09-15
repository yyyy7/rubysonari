package com.qiyu.languageserver;

import org.eclipse.lsp4j.*;
import org.eclipse.lsp4j.services.LanguageServer;
import org.eclipse.lsp4j.services.LanguageClient;
import org.eclipse.lsp4j.services.LanguageClientAware;
import org.eclipse.lsp4j.services.TextDocumentService;
import org.eclipse.lsp4j.services.WorkspaceService;
import org.yinwang.rubysonar.Binding;
import org.yinwang.rubysonar._;
import org.yinwang.rubysonar.ast.Node;
import org.yinwang.rubysonar.Analyzer;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Map.Entry;
import java.util.concurrent.CompletableFuture;

class RubyLanguageServer implements LanguageServer, LanguageClientAware {
  private LanguageClient client = null;
  public static Map<String, Map<Integer, Map<String, List<Map<String, Object>>>>> positions;
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

    positions = new LinkedHashMap<>();
    analyzer = Analyzer.newCachedInstance();
    analyzer.analyze(workspaceRoot.substring(7));
    analyzer.finish();
    generateRefs();

    ServerCapabilities capabilities = new ServerCapabilities();
    capabilities.setDefinitionProvider(true);
    // capabilities.setHoverProvider(true);

    return CompletableFuture.completedFuture(new InitializeResult(capabilities));
  }

  public void generateRefs() {

    for (Map.Entry<String, Map<Node, List<Binding>>> ee : analyzer.getReferences().entrySet()) {
      String file = ee.getKey();
      if (!positions.containsKey(file)) {
        positions.put(file, new LinkedHashMap<>());
      }

      for (Map.Entry<Node, List<Binding>> e : ee.getValue().entrySet()) {

        Node node = e.getKey();

        Map<Integer, Map<String, List<Map<String, Object>>>> fileRefs = positions.get(file);

        Map<String, List<Map<String, Object>>> lineRefs;
        if (!fileRefs.containsKey(node.line)) {
          fileRefs.put(node.line, new LinkedHashMap<>());
        }
        lineRefs = fileRefs.get(node.line);

        if (file != null) {
          String positionKey = node.col + "-" + (node.col + node.end - node.start);
          // _.msg("generate key: " + positionKey + " col: " + node.col + " end: " +
          // node.end + " start: " + node.start);

          List<Map<String, Object>> dests = new ArrayList<>();
          for (Binding b : e.getValue()) {
            String destFile = b.file;
            if (destFile != null) {
              Map<String, Object> dest = new LinkedHashMap<>();
              dest.put("name", b.node.name);
              dest.put("file", destFile);
              dest.put("start", b.start);
              dest.put("end", b.end);
              dest.put("line", b.node.line);
              dest.put("col", b.node.col);
              dests.add(dest);
            }
          }
          if (!dests.isEmpty()) {
            lineRefs.put(positionKey, dests);
          }

          // Map<String, Object> v = dests.get(0);
          // _.msg(file + " " + node.line + "-" + dests.size() + " " + node.name + " : " +
          // String.format("dest: %s %s %d %d ", v.get("name"), v.get("file"),
          // v.get("line"), v.get("col")));
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
      String uri = position.getTextDocument().getUri().substring(7);
      int line = position.getPosition().getLine() + 1;
      int col = position.getPosition().getCharacter() + 1;
      String positionKey = uri;
      /*
       * for (Entry<String, List<Map<String, Object>>> e :
       * RubyLanguageServer.positions.entrySet()) { _.msg("------Key: "+ e.getKey());
       * Map<String, Object> value = e.getValue().get(0); _.msg("------Value: " +
       * value.get("name") + " " + value.get("file") + " " + value.get("line") + " " +
       * value.get("col")); }
       */
      List<Map<String, Object>> dests = new ArrayList<>();
      Map<String, List<Map<String, Object>>> lineRefs = Optional.ofNullable(RubyLanguageServer.positions.get(uri))
          .map(h -> h.get(line)).orElse(Collections.emptyMap());
      for (Entry<String, List<Map<String, Object>>> r : lineRefs.entrySet()) {
        _.msg(r.getKey());
        Map<String, Object> v = r.getValue().get(0);
        _.msg(String.format("dest: %s %s %d %d ", v.get("name"), v.get("file"), v.get("line"), v.get("col")));

        String[] colRange = r.getKey().split("-");
        if (Integer.parseInt(colRange[0]) <= col && Integer.parseInt(colRange[1]) >= col) {
          dests = r.getValue();
        }
      }
      _.msg("======：" + position.toString());
      Range r;
      String targetFile = uri;
      List<Location> locations = new ArrayList<>();
      if (dests.size() == 0) {
        r = new Range();
      } else {
        for (Map<String, Object> dest : dests) {
          // Map<String, Object> dest = dests.get(0);
          targetFile = (String) dest.get("file");
          int targetLine = (int) dest.get("line") - 1;
          int targetCol = (int) dest.get("col") - 1;
          r = new Range(new Position(targetLine, targetCol), new Position(targetLine, targetCol + 1));
          locations.add(new Location("file://" + targetFile, r));
        }
      }
      // Location l = new Location("file://" + targetFile, r);
      // _.msg(l.toString());
      return CompletableFuture.completedFuture(locations);
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
        maxNumberOfProblems = ((Double) languageServerExample.getOrDefault("maxNumberOfProblems", 100.0)).intValue();
        fullTextDocumentService.documents.values().forEach(d -> validateDocument(d));
      }

      @Override
      public void didChangeWatchedFiles(DidChangeWatchedFilesParams params) {
        for (FileEvent f : params.getChanges()) {
          String filename = _.formatFileUri(f.getUri());
          analyzer.removeReferences(filename);
          initPostions(filename);
          // client.logMessage(new MessageParams(MessageType.Log, "We received an file
          // change event" + f.getUri()));
          analyzer.loadFileRecursive(filename);
          generatePositions(analyzer, filename);
        }
      }
    };
  }

  private void initPostions(String filename) {
    positions.put(filename, new LinkedHashMap<>());
  }

  private void generatePositions(Analyzer analyzer, String filename) {
    Map<Integer, Map<String, List<Map<String, Object>>>> fileRefs = positions.get(filename);
    for (Map.Entry<Node, List<Binding>> e : analyzer.getReferences(filename).entrySet()) {

      Node node = e.getKey();

      Map<String, List<Map<String, Object>>> lineRefs;
      if (!fileRefs.containsKey(node.line)) {
        fileRefs.put(node.line, new LinkedHashMap<>());
      }
      lineRefs = fileRefs.get(node.line);

      if (filename != null) {
        String positionKey = node.col + "-" + (node.col + node.end - node.start);
        List<Map<String, Object>> dests = new ArrayList<>();
        for (Binding b : e.getValue()) {
          String destFile = b.file;
          if (destFile != null) {
            Map<String, Object> dest = new LinkedHashMap<>();
            dest.put("name", b.node.name);
            dest.put("file", destFile);
            dest.put("start", b.start);
            dest.put("end", b.end);
            dest.put("line", b.node.line);
            dest.put("col", b.node.col);
            dests.add(dest);
          }
        }
        if (!dests.isEmpty()) {
          lineRefs.put(positionKey, dests);
        }
      }
    }
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