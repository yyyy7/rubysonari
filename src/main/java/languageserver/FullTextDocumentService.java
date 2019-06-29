package languageserver;

import org.eclipse.lsp4j.*;
import org.eclipse.lsp4j.jsonrpc.messages.Either;
import org.eclipse.lsp4j.services.TextDocumentService;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

import org.yinwang.rubysonar.Analyzer;
import org.yinwang.rubysonar.Binding;
import org.yinwang.rubysonar._;
import org.yinwang.rubysonar.ast.Node;

/**
 * `TextDocumentService` that only supports `TextDocumentSyncKind.Full` updates.
 *  Override members to add functionality.
 */
class FullTextDocumentService implements TextDocumentService {

    HashMap<String, TextDocumentItem> documents = new HashMap<>();

    private Analyzer analyzer;

    Map<String, List<Map<String, Object>>> positions;

    //private String workspaceRoot;

    //public FullTextDocumentService(String wsroot) {
    //    this.workspaceRoot = wsroot;
    //}

    public FullTextDocumentService() {}

    public FullTextDocumentService(String workspaceRoot) {
        _.msg("-------");
        _.msg(workspaceRoot);
        Map<String, Object> options = new HashMap<>();
        positions = new LinkedHashMap<>();
        analyzer = new Analyzer(options);
        analyzer.analyze(workspaceRoot);
        analyzer.getReferences();
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
                    }
                }
                if (!dests.isEmpty()) {
                    positions.put(positionKey, dests);
                }
            }
        }
    }

    @Override
    public CompletableFuture<Either<List<CompletionItem>, CompletionList>> completion(CompletionParams position) {
        return null;
    }


    @Override
    public CompletableFuture<SignatureHelp> signatureHelp(TextDocumentPositionParams position) {
        return null;
    }

    @Override
    public CompletableFuture<List<? extends Location>> definition(TextDocumentPositionParams position) {
        String uri = position.getTextDocument().getUri();
        int line = position.getPosition().getLine();
        int col = position.getPosition().getCharacter();
        String positionKey = uri + "-" + line + "-" + col;
        List<Map<String, Object>> dests = positions.get(positionKey);
        Range r;  
        if (dests == null) {
            r = new Range(new Position(line, col), new Position(line, col+1));
        } else {
            int targetLine = (int)dests.get(0).get("line");
            int targetCol = (int)dests.get(0).get("col");
            r = new Range(new Position(targetLine, targetCol), new Position(targetLine, targetCol+1));
        }
        return CompletableFuture.completedFuture(Arrays.asList(new Location(uri, r)));
    }

    @Override
    public CompletableFuture<Hover> hover(TextDocumentPositionParams position) {
      MarkedString markedString = new MarkedString("ruby", position.toString());
      Hover h = new Hover(Arrays.asList(Either.forRight(markedString)));

      return CompletableFuture.completedFuture(h);
    }

    @Override
    public CompletableFuture<CompletionItem> resolveCompletionItem(CompletionItem item) {
        if (item.getData().equals(1.0)) {
            item.setDetail("TypeScript details");
            item.setDocumentation("TypeScript documentation");
        } else if (item.getData().equals(2.0)) {
            item.setDetail("JavaScript details");
            item.setDocumentation("JavaScript documentation");
        }
        return CompletableFuture.completedFuture(item);
    }

    @Override
    public CompletableFuture<List<? extends Location>> references(ReferenceParams params) {
        return null;
    }

    @Override
    public CompletableFuture<List<? extends DocumentHighlight>> documentHighlight(TextDocumentPositionParams position) {
        return null;
    }

    @Override
    public CompletableFuture<List<? extends SymbolInformation>> documentSymbol(DocumentSymbolParams params) {
        return null;
    }

    @Override
    public CompletableFuture<List<? extends Command>> codeAction(CodeActionParams params) {
        return null;
    }

    @Override
    public CompletableFuture<List<? extends CodeLens>> codeLens(CodeLensParams params) {
        return null;
    }

    @Override
    public CompletableFuture<CodeLens> resolveCodeLens(CodeLens unresolved) {
        return null;
    }

    @Override
    public CompletableFuture<List<? extends TextEdit>> formatting(DocumentFormattingParams params) {
        return null;
    }

    @Override
    public CompletableFuture<List<? extends TextEdit>> rangeFormatting(DocumentRangeFormattingParams params) {
        return null;
    }

    @Override
    public CompletableFuture<List<? extends TextEdit>> onTypeFormatting(DocumentOnTypeFormattingParams params) {
        return null;
    }

    @Override
    public CompletableFuture<WorkspaceEdit> rename(RenameParams params) {
        return null;
    }

    @Override
    public void didOpen(DidOpenTextDocumentParams params) {
       
        documents.put(params.getTextDocument().getUri(), params.getTextDocument());
    }

    @Override
    public void didChange(DidChangeTextDocumentParams params) {
        String uri = params.getTextDocument().getUri();
        for (TextDocumentContentChangeEvent changeEvent : params.getContentChanges()) {
            // Will be full update because we specified that is all we support
            if (changeEvent.getRange() != null) {
                throw new UnsupportedOperationException("Range should be null for full document update.");
            }
            if (changeEvent.getRangeLength() != null) {
                throw new UnsupportedOperationException("RangeLength should be null for full document update.");
            }

            documents.get(uri).setText(changeEvent.getText());
        }
    }

    @Override
    public void didClose(DidCloseTextDocumentParams params) {
        String uri = params.getTextDocument().getUri();
        documents.remove(uri);
    }

    @Override
    public void didSave(DidSaveTextDocumentParams params) {
    }
}
