module otya.smilebasic.error;
import std.exception;
import std.string;
import std.conv;
import otya.smilebasic.token;

class SmileBasicError : Exception
{
    int errnum;
    int errline;
    int errprg;
    string message2;
    string func;
    this(int slot, int line, string message)
    {
        super(format("%s in %d:%d", message, slot, line));
    }
    this(int line, string message)
    {
        super(format("%s in %d", message, line));
    }
    this(string message)
    {
        super(message);
    }
    this(string message, string message2)
    {
        super(message);
        this.message2 = message2;
    }
    string getErrorMessage()
    {
        return this.msg;
    }
    //詳細
    string getErrorMessage2()
    {
        return message2;
    }
}
class InternalError : SmileBasicError
{
    this()
    {
        this.errnum = 1;
        super("Internal Error");
    }
    Throwable throwable;
    this(Throwable throwable)
    {
        this.throwable = throwable;
        this.errnum = 1;
        super("Internal Error");
    }
}
class SyntaxError : SmileBasicError
{
    this()
    {
        this.errnum = 3;
        super("Syntax error");
    }
    this(wstring func)
    {
        this();
        this.message2 = "Undefined function (" ~ func.to!string ~ ")";
    }
}
class IllegalFunctionCall : SmileBasicError
{
    this()
    {
        this.errnum = 4;
        super("Illegal function call");
    }
    this(string func)
    {
        this.errnum = 4;
        super("Illegal function call(" ~ func ~ ")");
    }
    this(string func, int arg)
    {
        this.errnum = 4;
        super("Illegal function call(" ~ func ~ ":" ~ arg.to!string ~ ")");
    }
}
class StackOverFlow : SmileBasicError
{
    this()
    {
        this.errnum = 5;
        super("Stack overflow");
    }
}
class StackUnderFlow : SmileBasicError
{
    this()
    {
        this.errnum = 6;
        super("Stack underflow");
    }
}
class TypeMismatch : SmileBasicError
{
    this()
    {
        this.errnum = 8;
        super("Type mismatch");
    }
    this(string func)
    {
        this.errnum = 8;
        super("Type mismatch(" ~ func ~ ")");
    }
    this(string func, int arg)
    {
        this.errnum = 8;
        super("Type mismatch(" ~ func ~ ":" ~ arg.to!string ~ ")");
    }
}
class OutOfRange : SmileBasicError
{
    this()
    {
        this.errnum = 10;
        super("Out of range");
    }
    this(string func)
    {
        this.errnum = 10;
        super("Out of range(" ~ func ~ ")");
    }
    this(string func, int arg)
    {
        this.errnum = 10;
        super("Out of range(" ~ func ~ ":" ~ arg.to!string ~ ")");
    }
}
class OutOfDATA : SmileBasicError
{
    this()
    {
        this.errnum = 13;
        super("Out of DATA");
    }
}
class UndefinedLabel : SmileBasicError
{
    this()
    {
        this.errnum = 14;
        super("Undefined label");
    }
    this(wstring label)
    {
        this();
    }
}
class UndefinedVariable : SmileBasicError
{
    this()
    {
        this.errnum = 15;
        super("Undefined variable");
    }
}
class UndefinedFunction : SmileBasicError
{
    this()
    {
        this.errnum = 16;
        super("Undefined function");
    }
    this(wstring name)
    {
        this();
    }
}
class DuplicateVariable : SmileBasicError
{
    this()
    {
        this.errnum = 18;
        super("Duplicate variable");
    }
}
class DuplicateFunction : SmileBasicError
{
    this(int slot, SourceLocation loc)
    {
        this.errnum = 19;
        super(slot, loc.line, "Duplicate function");
    }
}
class ReturnWithoutGosub : SmileBasicError
{
    this()
    {
        this.errnum = 30;
        super("RETURN without GOSUB");
    }
}
class SubscriptOutOfRange : SmileBasicError
{
    this()
    {
        this.errnum = 31;
        super("Subscript out of range");
    }
    this(string func)
    {
        this.errnum = 31;
        super("Subscript out of range(" ~ func ~ ")");
    }
    this(string func, int arg)
    {
        this.errnum = 31;
        super("Subscript out of range(" ~ func ~ ":" ~ arg.to!string ~ ")");
    }
}
class IllegalSymbolString : SmileBasicError
{
    this()
    {
        this.errnum = 34;
        super("Illegal symbol string");
    }
}
class IllegalFileFormat : SmileBasicError
{
    this(string func)
    {
        this.errnum = 35;
        super("Illegal file format(" ~ func ~ ")");
    }
}
class UsePRGEDITBeforeAnyPRGFunction : SmileBasicError
{
    this(string func)
    {
        this.errnum = 38;
        super("Use PRGEDIT before any PRG function(" ~ func ~ ")");
    }
}
class StringTooLong : SmileBasicError
{
    this()
    {
        this.errnum = 41;
        super("String too long");
    }
    this(string func)
    {
        this.errnum = 41;
        super("String too long(" ~ func ~ ")");
    }
    this(string func, int arg)
    {
        this.errnum = 41;
        super("String too long(" ~ func ~ ":" ~ arg.to!string ~ ")");
    }
}
class CantUseFromDirectMode : SmileBasicError
{
    this()
    {
        this.errnum = 43;
        this.errprg = 0;//always 0
        this.errline = 0;
        super("Can't use from direct mode");
    }
}
class CantUseInProgram : SmileBasicError
{
    this(wstring func)
    {
        this.errnum = 44;
        super("Can't use in program");
    }
}

class LoadFailed : SmileBasicError
{
    this()
    {
        this.errnum = 46;
        super("Load failed");
    }
}


