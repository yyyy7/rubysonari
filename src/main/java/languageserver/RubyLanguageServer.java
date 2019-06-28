package languageserver;

import org.eclipse.lsp4j.*;
import org.eclipse.lsp4j.jsonrpc.messages.Either;
import org.eclipse.lsp4j.services.LanguageServer;
import org.eclipse.lsp4j.services.LanguageClient;
import org.eclipse.lsp4j.services.LanguageClientAware;
import org.eclipse.lsp4j.services.TextDocumentService;
import org.eclipse.lsp4j.services.WorkspaceService;
import org.yinwang.rubysonar._;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

class RubyLanguageServer implements LanguageServer, LanguageClientAware {
  private LanguageClient client = null;

  @SuppressWarnings("unused")
  private String workspaceRoot = null;

  @Override
  public CompletableFuture<InitializeResult> initialize(InitializeParams params) {
    _.msg(params.toString());
    workspaceRoot = params.getRootUri();
    if (workspaceRoot == null || workspaceRoot == "") {
      throw new RuntimeException("got " + workspaceRoot);
    } 

    ServerCapabilities capabilities = new ServerCapabilities();
    capabilities.setDefinitionProvider(true);
    capabilities.setHoverProvider(true);

    return CompletableFuture.completedFuture(new InitializeResult(capabilities));
  }

  @Override
  public CompletableFuture<Object> shutdown() {
    return  CompletableFuture.completedFuture(null);
  }

  @Override
  public void exit() {
  }

  @Override
  public void connect(LanguageClient client) {
    this.client = client;
  }

  private FullTextDocumentService fullTextDocumentService = new FullTextDocumentService(workspaceRoot);

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