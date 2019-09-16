package org.yinwang.rubysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.rubysonar.*;
import org.yinwang.rubysonar.types.ModuleType;
import org.yinwang.rubysonar.types.Type;


public class Moduler extends Node {

    public Node locator;
    public Name name;
    public Block body;
    public Str docstring;


    public Moduler(Node locator, Block body, Str docstring, String file, int start, int end, int line, int col) {
        super(file, start,end, line, col);
        this.locator = locator;
        this.body = body;
        this.docstring = docstring;
        if (locator instanceof Attribute) {
            this.name = ((Attribute) locator).attr;
        } else if (locator instanceof Name) {
            this.name = (Name) locator;
        } else {
            Utils.die("illegal module locator: " + locator);
        }
        addChildren(locator, body);
    }


    @NotNull
    @Override
    public Type transform(@NotNull State s) {
        if (name.id.equals("ClassMethods")) {
            boolean saved = Analyzer.self.staticContext;
            Analyzer.self.setStaticContext(true);
            transformExpr(body, s);
            Analyzer.self.setStaticContext(saved);
            return Type.NIL;
        } else {
            ModuleType mt = s.lookupOrCreateModuler(locator, file);
            mt.table.insert(Constants.SELFNAME, name, mt, Binding.Kind.SCOPE);
            transformExpr(body, mt.table);
            return mt;
        }
    }


    @NotNull
    @Override
    public String toString() {
        return "(module:" + locator + ")";
    }

}
