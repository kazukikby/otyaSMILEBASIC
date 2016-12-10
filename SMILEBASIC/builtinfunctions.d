module otya.smilebasic.builtinfunctions;

import std.conv;
import std.typecons;
import std.typetuple;
import std.traits;
import std.stdio;
import std.ascii;
import std.range;
import std.string;
import otya.smilebasic.error;
import otya.smilebasic.type;
import otya.smilebasic.petitcomputer;
import otya.smilebasic.sprite;
import otya.smilebasic.vm;
//プチコンの引数省略は特殊なので
//LOCATE ,,0のように省略できる
struct DefaultValue(T, bool skippable = true)
{
    T value;
    bool isDefault;
    this(T v, bool f)
    {
        value = v;
        isDefault = f;
    }
    this(T v)
    {
        value = v;
        isDefault = false;
    }
    this(bool f)
    {
        isDefault = f;
    }
    void setDefaultValue(T v)
    {
        if(isDefault)
            value = v;
    }
    mixin Proxy!value;
}
struct StartOptional
{
    const char[] name;
}
struct BasicName
{
    wstring naame;
}
alias ValueType = otya.smilebasic.type.ValueType;
struct BuiltinFunctionArgument
{
    ValueType argType;
    bool optionalArg;
    bool skipArg;
}
//オーバーロード用
class BuiltinFunctions
{
    private BuiltinFunction[] func;
    this(BuiltinFunction f)
    {
        func = new BuiltinFunction[1];
        func[0] = f;
    }
    void addFunction(BuiltinFunction func)
    {
        this.func ~= func;
    }
    BuiltinFunction overloadResolution(size_t argc, size_t outargc)
    {
        BuiltinFunction va;
        //とりあえず引数の数で解決させる,というよりコンパイル時に型を取得する方法がない
        foreach(f; func)
        {
            if(f.startskip <= argc && f.argments.length >= argc)
                if((f.outoptional != 0 && f.outoptional <= outargc && f.results.length >= outargc) || f.results.length == outargc)
                return f;
            if(f.variadic)
                va = f;
        }
        //一応可変長は最後
        if(va) return va;
        writeln("====function overloads===");
        writefln("func = %s argc = %d outargc = %d", func[0].name, argc, outargc);
        foreach(f; func)
        {
            writefln("name=\"%s\", argments=%s, results = %s, variadic = %s, startoptional = %d, function pointer=%s", f.name, f.argments, f.results, f.variadic, f.startskip, f.func);
        }
        //引数数ちがうのは実行前にエラー
        throw new IllegalFunctionCall(func[0].name);
    }
}
alias DefaultValue!(int, false) optionalint;
alias DefaultValue!(int, false) optionaldouble;
alias DefaultValue!(int, false) optionalstring;
/**
ここに関数を定義すればコンパイル時にBuiltinFunctionに変換してくれる便利なクラス
*/
class BuiltinFunction
{
    BuiltinFunctionArgument[] argments;
    BuiltinFunctionArgument[] results;
    void function(PetitComputer, Value[], Value[]) func;
    int startskip;
    int outoptional;
    bool variadic;
    string name;
    this(BuiltinFunctionArgument[] argments, BuiltinFunctionArgument[] results, void function(PetitComputer, Value[], Value[]) func, int startskip,
         bool variadic, string name, int outoptional)
    {
        this.argments = argments;
        this.results = results;
        this.func = func;
        this.startskip = startskip;
        this.variadic = variadic;
        this.name = name;
        this.outoptional = outoptional;
    }
    bool hasSkipArgument()
    {
        return this.startskip != this.argments.length;
    }
    import std.math;
    /*
    static pure double ABS(double a)
    {
        return a < 0 ? -a : a;
    }*/
    //static double function(double) ABS = &abs!double;
    //static double function(double) SGN = &sgn!double;
    static Value ABS(Value arg1)
    {
        if (arg1.isInteger)
        {
            return Value(abs(arg1.integerValue));
        }
        else
        {
            return Value(abs(arg1.castDouble));
        }
    }
    static pure nothrow @nogc @trusted int SGN(double arg1)
    {
        if (isNaN(arg1))
        {
            return 1;
        }
        return arg1 > 0 ? 1 : arg1 ? -1 : 0;
    }
    static pure nothrow double SIN(double arg1)
    {
        return sin(arg1);
    }
    static double ASIN(double arg1)
    {
        if (arg1 >= -1 && arg1 <= 1)
        {
            return asin(arg1);
        }
        else
        {
            throw new OutOfRange();
        }
    }
    static pure nothrow double SINH(double arg1)
    {
        return sinh(arg1);
    }
    static pure nothrow double COS(double arg1)
    {
        return cos(arg1);
    }
    static double ACOS(double arg1)
    {
        if (arg1 >= -1 && arg1 <= 1)
        {
            return acos(arg1);
        }
        else
        {
            throw new OutOfRange();
        }
    }
    static pure nothrow double COSH(double arg1)
    {
        return cosh(arg1);
    }
    static pure nothrow double TAN(double arg1)
    {
        return tan(arg1);
    }
    static pure nothrow double ATAN(double arg1, DefaultValue!(double, false) arg2)
    {
        if(arg2.isDefault)
        {
            return atan(arg1);
        }
        return atan2(arg1, cast(double)arg2);
    }
    static pure nothrow double TANH(double arg1)
    {
        return tanh(arg1);
    }
    enum Classify
    {
        NORMAL = 0,
        INFINITY = 1,
        NAN = 2,
    }
    static pure nothrow int CLASSIFY(double arg)
    {
        if (arg.isNaN)
        {
            return Classify.NAN;
        }
        if (arg.isInfinity)
        {
            return Classify.INFINITY;
        }
        return Classify.NORMAL;
    }
    static pure nothrow double RAD(double arg1)
    {
        return arg1 * std.math.PI / 180;
    }
    static pure nothrow double DEG(double arg1)
    {
        return arg1 * 180 / std.math.PI;
    }
    static pure nothrow double PI()
    {
        return std.math.PI;
    }
    //static ABS = function double(double x) => abs(this.result == ValueType.Double ? 1 : 0);
    static void LOCATE(PetitComputer p, DefaultValue!int x, DefaultValue!int y, DefaultValue!(int, false) z)
    {
        x.setDefaultValue(p.console.CSRX);
        y.setDefaultValue(p.console.CSRY);
        z.setDefaultValue(p.console.CSRZ);
        p.console.CSRX = cast(int)x;
        p.console.CSRY = cast(int)y;
        p.console.CSRZ = cast(int)z;
    }
    static void COLOR(PetitComputer p, DefaultValue!int fore, DefaultValue!(int, false) back)
    {
        fore.setDefaultValue(p.console.consoleForeColor);
        back.setDefaultValue(p.console.consoleBackColor);
        p.console.consoleForeColor = cast(int)fore;
        p.console.consoleBackColor = cast(int)back;
    }
    static void ATTR(PetitComputer p, int attr)
    {
        if (attr < 0 || attr > 15)
            throw new OutOfRange("ATTR", 1);
        p.console.attr = cast(otya.smilebasic.console.ConsoleAttribute)attr;
    }
    static void WIDTH(PetitComputer p, int width)
    {
        if (width != 8 && width != 16)
        {
            throw new IllegalFunctionCall("WIDTH", 1);
        }
        p.console.width = width;
    }
    static int WIDTH(PetitComputer p)
    {
        return p.console.width;
    }
    static void VSYNC(PetitComputer p, DefaultValue!int time)
    {
        time.setDefaultValue(1);
        p.vsync(cast(int)time);
    }
    static void WAIT(PetitComputer p, DefaultValue!int time)
    {
        time.setDefaultValue(1);
        p.vsync(cast(int)time);
    }
    //TODO:プチコンのCLSには引数の個数制限がない
    static void CLS(PetitComputer p/*vaarg*/)
    {
        p.console.cls;
    }
    static void ASSERT__(PetitComputer p, int cond, wstring message)
    {
        if(!cond)
        {
            p.console.print("Assertion failed: ", message, "\n");
        }
        assert(cond, message.to!string);
    }
    static int BUTTON(PetitComputer p, DefaultValue!(int, false) mode, DefaultValue!(int, false) mp)
    {
        if(!mp.isDefault)
        {
            writeln("NOTIMPL:BUTTON(ID, MPID)");
        }
        return p.button;
    }
    static void BREPEAT(PetitComputer p, int btnid, int startTime, int interval)
    {
        stderr.writefln("NOTIMPL:BREPEAT %d, %d, %d", btnid, startTime, interval);
    }
    static void VISIBLE(PetitComputer p, int console, int graphic, int BG, int sprite)
    {
        import std.exception : enforce;
        enforce(console == 0 || console == 1, new OutOfRange("VISIBLE", 1));
        enforce(graphic == 0 || graphic == 1, new OutOfRange("VISIBLE", 2));
        enforce(BG == 0 || BG == 1, new OutOfRange("VISIBLE", 3));
        enforce(sprite == 0 || sprite == 1, new OutOfRange("VISIBLE", 4));
        p.console.visible = cast(bool)console;
        p.graphic.visible = cast(bool)graphic;
        p.BGvisible = cast(bool)BG;
        p.sprite.visible = cast(bool)sprite;
    }
    static void BACKCOLOR(PetitComputer p, int color)
    {
        p.backcolor = color;
    }
    static int BACKCOLOR(PetitComputer p)
    {
        return p.backcolor;
    }
    static void XON(PetitComputer p, Value mode/*!?!???!?*/)
    {
    }
    static void XOFF(PetitComputer p, Value mode/*!?!???!?*/)
    {
    }
    static void TOUCH(PetitComputer p, DefaultValue!(int, false) id, out int tm, out int tchx, out int tchy)
    {
        if(!id.isDefault)
        {
            writeln("NOTIMPL:TOUCH MPID");
        }
        auto pos = p.touchPosition;
        tm = pos.tm;
        tchx = pos.x;
        tchy = pos.y;
    }
    static void XSCREEN(PetitComputer p, int mode, int tv, int gamepad, int sp, int bg)
    {
        if (p.x.mode != PetitComputer.XMode.WIIU || mode != 6)
        {
            throw new IllegalFunctionCall("XSCREEN");
        }
        p.xscreen(mode, tv, gamepad, sp, bg);
    }
    static void XSCREEN(PetitComputer p, int mode, int tv, int sp, int bg)
    {
        if (p.x.mode != PetitComputer.XMode.WIIU || mode != 5)
        {
            throw new IllegalFunctionCall("XSCREEN");
        }
        p.xscreen(mode, tv, sp, bg);
    }
    static void XSCREEN(PetitComputer p, int mode, int tv)
    {
        XSCREEN(p, mode, tv, 4096, 4);
    }
    static void XSCREEN(PetitComputer p, int mode)
    {
        if(mode == 2 || mode == 3)
        {
            p.xscreen(mode, 256, 2);
        }
        else
        {
            p.xscreen(mode, 512, 4);
        }
    }
    static void XSCREEN(PetitComputer p, int mode, int sp, int bg)
    {
        if (mode == 6)
        {
            XSCREEN(p, mode, sp, bg, 2048, 2);
            return;
        }
        p.xscreen(mode, sp, bg);
    }
    static void DISPLAY(PetitComputer p, int display)
    {
        p.display(display);
    }
    static int DISPLAY(PetitComputer p)
    {
        return p.displaynum;
    }
    static void GCLS(PetitComputer p, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(0);
        p.graphic.gfill(p.graphic.useGRP, 0, 0, 511, 511, cast(int)color);
    }
    static void GPSET(PetitComputer p, int x, int y, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(p.graphic.gcolor);
        p.graphic.gpset(p.graphic.useGRP, x, y, cast(int)color);
    }
    static void GLINE(PetitComputer p, int x, int y, int x2, int y2, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(p.graphic.gcolor);
        p.graphic.gline(p.graphic.useGRP, x, y, x2, y2, cast(int)color);
    }
    static void GBOX(PetitComputer p, int x, int y, int x2, int y2, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(p.graphic.gcolor);
        p.graphic.gbox(p.graphic.useGRP, x, y, x2, y2, cast(int)color);
    }
    static void GFILL(PetitComputer p, int x, int y, int x2, int y2, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(p.graphic.gcolor);
        p.graphic.gfill(p.graphic.useGRP, x, y, x2, y2, cast(int)color);
    }
    //X,Y,R[,COLOR]
    //X,Y,R,SR,ER[,COLOR]
    static void GCIRCLE(PetitComputer p, int x, int y, int r, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(p.graphic.gcolor);
        p.graphic.gcircle(p.graphic.useGRP, x, y, r, cast(int)color);
    }
    static void GCIRCLE(PetitComputer p, int x, int y, int r, int sr, int er, DefaultValue!(int, false) flag, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(p.graphic.gcolor);
        flag.setDefaultValue(0);
        p.graphic.gcircle(p.graphic.useGRP, x, y, r, sr, er, cast(int)flag, cast(int)color);
    }
    static void GCOLOR(PetitComputer p, int color)
    {
        p.graphic.gcolor = color;
    }
    static void GPRIO(PetitComputer p, int z)
    {
        p.graphic.gprio = z;
    }
    static void GPAGE(PetitComputer p, int showPage, int usePage)
    {
        p.graphic.showGRP = showPage;
        p.graphic.useGRP = usePage;
    }
    static void GCLIP(PetitComputer p, int clipmode)
    {
        p.graphic.clip(cast(bool)clipmode/*not checked*/);
    }
    static void GCLIP(PetitComputer p, int clipmode, int sx, int sy, int ex, int ey)
    {
        import std.algorithm : swap;
        if (sx < 0 || sy < 0 || ex < 0 || ey < 0)
            throw new OutOfRange("GCLIP");
        if (clipmode)
        {
            if (sx >= 512 || sy >= 512 || ex >= 512 || ey >= 512)
                throw new OutOfRange("GCLIP");
        }
        if (sx > ex)
        {
            swap(sx, ex);
        }
        if (sy > ey)
        {
            swap(sy, ey);
        }
        int x = sx;
        int y = sy;
        int w = ex - sx + 1;
        int h = ey - sy + 1;
        p.graphic.clip(cast(bool)clipmode/*not checked*/, x, y, w, h);
    }
    static void GPAINT(PetitComputer p, int x, int y, DefaultValue!(int, false) color, DefaultValue!(int, false) color2)
    {
        color.setDefaultValue(p.graphic.gcolor);
        p.graphic.gpaint(p.graphic.useGRP, x, y, cast(int)color);
    }
    static void GPUTCHR(PetitComputer p, int x, int y, Value str)
    {
        GPUTCHR(p, x, y, str, 1, 1, p.graphic.gcolor);
    }
    static void GPUTCHR(PetitComputer p, int x, int y, Value str, int color)
    {
        GPUTCHR(p, x, y, str, 1, 1, p.graphic.gcolor);
    }
    static void GPUTCHR(PetitComputer p, int x, int y, Value str, int scalex, int scaley)
    {
        GPUTCHR(p, x, y, str, scalex, scaley, p.graphic.gcolor);
    }
    static void GPUTCHR(PetitComputer p, int x, int y, Value str, int scalex, int scaley, int color)
    {
        if (str.isNumber)
        {
            p.graphic.gputchr(p.graphic.useGRP, x, y, str.castInteger, scalex, scaley, color);
        }
        else if (str.isString)
        {
            p.graphic.gputchr(p.graphic.useGRP, x, y, str.castString, scalex, scaley, color);
        }
        else
        {
            throw new TypeMismatch("GPUTCHR", 3);
        }
    }
    static void BGMPLAY(PetitComputer p, int music)
    {
    }
    static void BEEP(PetitComputer p, DefaultValue!(int, false) beep, DefaultValue!(int, false) pitch, DefaultValue!(int, false) volume, DefaultValue!(int, false) pan)
    {
    }
    static void STICK(PetitComputer p, DefaultValue!(int, false) mp, out int x, out int y)
    {
        //JOYSTICK?
        x = 0;
        y = 0;
    }
    static void STICKEX(PetitComputer p, DefaultValue!(int, false) mp, out int x, out int y)
    {
        //JOYSTICK?
        x = 0;
        y = 0;
    }
    static pure nothrow int RGB(int R, int G, int B, DefaultValue!(int, false) _)
    {
        if(!_.isDefault)
        {
            //やや強引なオーバーロード
            return PetitComputer.RGB(cast(ubyte)R, cast(ubyte)G, cast(ubyte)B, cast(ubyte)_);
        }
        return PetitComputer.RGB(cast(ubyte)R, cast(ubyte)G, cast(ubyte)B);
    }
    static int RND(int max)
    {
        import std.random;
        return uniform(0, max);
    }
    static double RNDF()
    {
        import std.random;
        return uniform(0.0, 1.0);
    }
    static void DTREAD(DefaultValue!(wstring, false) date, out int Y, out int M, out int D/*W*/)
    {
        import std.datetime;
        auto currentTime = Clock.currTime();
        if(date.isDefault)
        {
            Y = currentTime.year;
            M = currentTime.month;
            D = currentTime.day;
        }
        else
        {
            import std.format;
            auto v = date.value;
            formattedRead(v, "%d/%d/%d", &Y, &M, &D);
        }
    }
    static int LEN(Value ary)
    {
        return ary.length;
    }

    static bool tryParse(Target, Source)(ref Source p, out Target result)
        if (isInputRange!Source && isSomeChar!(ElementType!Source) && !is(Source == enum) &&
            isFloatingPoint!Target && !is(Target == enum))
        {
            static immutable real[14] negtab =
            [ 1e-4096L,1e-2048L,1e-1024L,1e-512L,1e-256L,1e-128L,1e-64L,1e-32L,
            1e-16L,1e-8L,1e-4L,1e-2L,1e-1L,1.0L ];
            static immutable real[13] postab =
            [ 1e+4096L,1e+2048L,1e+1024L,1e+512L,1e+256L,1e+128L,1e+64L,1e+32L,
            1e+16L,1e+8L,1e+4L,1e+2L,1e+1L ];
            // static immutable string infinity = "infinity";
            // static immutable string nans = "nans";

            /*ConvException bailOut(string msg = null, string fn = __FILE__, size_t ln = __LINE__)
            {
                if (!msg)
                    msg = "Floating point conversion error";
                return new ConvException(text(msg, " for input \"", p, "\"."), fn, ln);
            }*/
            if(p.empty) return 0;
            //enforce(!p.empty, bailOut());

            char sign = 0;                       /* indicating +                 */
            switch (p.front)
            {
                case '-':
                    sign++;
                    p.popFront();
                    if(p.empty) return 0;
                    //enforce(!p.empty, bailOut());
                    if(p.empty) return 0;
                    //enforce(!p.empty, bailOut());
                    break;
                case '+':
                    p.popFront();
                    if(p.empty) return 0;
                    //enforce(!p.empty, bailOut());
                    break;
                default: {}
            }

            bool isHex = false;
            bool startsWithZero = p.front == '0';
            if(startsWithZero)
            {
                p.popFront();
                if(p.empty)
                {
                    result = (sign) ? -0.0 : 0.0;
                    return true;
                }

                isHex = p.front == 'x' || p.front == 'X';
            }

            real ldval = 0.0;
            char dot = 0;                        /* if decimal point has been seen */
            int exp = 0;
            long msdec = 0, lsdec = 0;
            ulong msscale = 1;

            if (isHex)
            {
                int guard = 0;
                int anydigits = 0;
                uint ndigits = 0;

                p.popFront();
                while (!p.empty)
                {
                    int i = p.front;
                    while (isHexDigit(i))
                    {
                        anydigits = 1;
                        i = std.ascii.isAlpha(i) ? ((i & ~0x20) - ('A' - 10)) : i - '0';
                        if (ndigits < 16)
                        {
                            msdec = msdec * 16 + i;
                            if (msdec)
                                ndigits++;
                        }
                        else if (ndigits == 16)
                        {
                            while (msdec >= 0)
                            {
                                exp--;
                                msdec <<= 1;
                                i <<= 1;
                                if (i & 0x10)
                                    msdec |= 1;
                            }
                            guard = i << 4;
                            ndigits++;
                            exp += 4;
                        }
                        else
                        {
                            guard |= i;
                            exp += 4;
                        }
                        exp -= dot;
                        p.popFront();
                        if (p.empty)
                            break;
                        i = p.front;
                        if (i == '_')
                        {
                            p.popFront();
                            if (p.empty)
                                break;
                            i = p.front;
                        }
                    }
                    if (i == '.' && !dot)
                    {       p.popFront();
                        dot = 4;
                    }
                    else
                        break;
                }

                // Round up if (guard && (sticky || odd))
                if (guard & 0x80 && (guard & 0x7F || msdec & 1))
                {
                    msdec++;
                    if (msdec == 0)                 // overflow
                    {   msdec = 0x8000000000000000L;
                        exp++;
                    }
                }

                if(!anydigits) return 0;
                //enforce(anydigits, bailOut());
                if(!(!p.empty && (p.front == 'p' || p.front == 'P'))) return 0;
                //enforce(!p.empty && (p.front == 'p' || p.front == 'P'),
                //        bailOut("Floating point parsing: exponent is required"));
                char sexp;
                int e;

                sexp = 0;
                p.popFront();
                if (!p.empty)
                {
                    switch (p.front)
                    {   case '-':    sexp++;
                        goto case;
                    case '+':    p.popFront(); 
                        if(p.empty) return 0;
                        //enforce(!p.empty,
                        //            new ConvException("Error converting input"
                        //            " to floating point"));
                        break;
                    default: {}
                    }
                }
                ndigits = 0;
                e = 0;
                while (!p.empty && isDigit(p.front))
                {
                    if (e < 0x7FFFFFFF / 10 - 10) // prevent integer overflow
                    {
                        e = e * 10 + p.front - '0';
                    }
                    p.popFront();
                    ndigits = 1;
                }
                exp += (sexp) ? -e : e;
                if(p.empty) return 0;
                //enforce(ndigits, new ConvException("Error converting input"
                //" to floating point"));

                if (msdec)
                {
                    int e2 = 0x3FFF + 63;

                    // left justify mantissa
                    while (msdec >= 0)
                    {   msdec <<= 1;
                        e2--;
                    }

                    // Stuff mantissa directly into real
                    *cast(long *)&ldval = msdec;
                    (cast(ushort *)&ldval)[4] = cast(ushort) e2;

                    // Exponent is power of 2, not power of 10
                    ldval = ldexp(ldval,exp);
                }
                goto L6;
            }
            else // not hex
            {

                bool sawDigits = startsWithZero;

                while (!p.empty)
                {
                    int i = p.front;
                    while (isDigit(i))
                    {
                        sawDigits = true;        /* must have at least 1 digit   */
                        if (msdec < (0x7FFFFFFFFFFFL-10)/10)
                            msdec = msdec * 10 + (i - '0');
                        else if (msscale < (0xFFFFFFFF-10)/10)
                        {   lsdec = lsdec * 10 + (i - '0');
                            msscale *= 10;
                        }
                        else
                        {
                            exp++;
                        }
                        exp -= dot;
                        p.popFront();
                        if (p.empty)
                            break;
                        i = p.front;
                        if (i == '_')
                        {
                            p.popFront();
                            if (p.empty)
                                break;
                            i = p.front;
                        }
                    }
                    if (i == '.' && !dot)
                    {
                        p.popFront();
                        dot++;
                    }
                    else
                    {
                        break;
                    }
                }
                if(!sawDigits) return 0;
                //enforce(sawDigits, new ConvException("no digits seen"));
            }
            if (!p.empty && (p.front == 'e' || p.front == 'E'))
            {
                char sexp;
                int e;

                sexp = 0;
                p.popFront();
                if(p.empty) return false;
                //enforce(!p.empty, new ConvException("Unexpected end of input"));
                switch (p.front)
                {   case '-':    sexp++;
                    goto case;
                case '+':    p.popFront();
                    break;
                default: {}
                }
                bool sawDigits = 0;
                e = 0;
                while (!p.empty && isDigit(p.front))
                {
                    if (e < 0x7FFFFFFF / 10 - 10)   // prevent integer overflow
                    {
                        e = e * 10 + p.front - '0';
                    }
                    p.popFront();
                    sawDigits = 1;
                }
                exp += (sexp) ? -e : e;
                if(!sawDigits) return 0;
                //enforce(sawDigits, new ConvException("No digits seen."));
            }

            ldval = msdec;
            if (msscale != 1)               /* if stuff was accumulated in lsdec */
                ldval = ldval * msscale + lsdec;
            if (ldval)
            {
                uint u = 0;
                int pow = 4096;

                while (exp > 0)
                {
                    while (exp >= pow)
                    {
                        ldval *= postab[u];
                        exp -= pow;
                    }
                    pow >>= 1;
                    u++;
                }
                while (exp < 0)
                {
                    while (exp <= -pow)
                    {
                        ldval *= negtab[u];
                        if(ldval == 0) return 0;
                        //enforce(ldval != 0, new ConvException("Range error"));
                        exp += pow;
                    }
                    pow >>= 1;
                    u++;
                }
            }
        L6: // if overflow occurred
            if(ldval == core.stdc.math.HUGE_VAL) return 0;
            //enforce(ldval != core.stdc.math.HUGE_VAL, new ConvException("Range error"));

        L1:
            result = (sign) ? -ldval : ldval;
            return true;
        }

    /// ditto
    static bool tryParse(Target, Source)(ref Source s, uint radix, out Target result)
        if (isSomeChar!(ElementType!Source) &&
            isIntegral!Target && !is(Target == enum))
    {
        if (!(radix >= 2 && radix <= 36))
        {
            result = 0;
            return false;
        }
        import core.checkedint : mulu, addu;

        immutable uint beyond = (radix < 10 ? '0' : 'a'-10) + radix;

        Target v = 0;
        bool atStart = true;

        for (; !s.empty; s.popFront())
        {
            uint c = s.front;
            if (c < '0')
                break;
            if (radix < 10)
            {
                if (c >= beyond)
                    break;
            }
            else
            {
                if (c > '9')
                {
                    c |= 0x20;//poorman's tolower
                    if (c < 'a' || c >= beyond)
                        break;
                    c -= 'a'-10-'0';
                }
            }

            bool overflow = false;
            auto nextv = v.mulu(radix, overflow).addu(c - '0', overflow);
            if (overflow || nextv > Target.max)
                goto Loverflow;
            v = cast(Target) nextv;

            atStart = false;
        }
        if (atStart)
            goto Lerr;
        result = v;
        return true;

    Loverflow:
        result = 0;
        return false;
    Lerr:
        result = 0;
        return false;
    }
    static double VAL(wstring str)
    {
        munch(str, " ");
        if(str.length > 2 && str[0..2] == "&H")
        {
            int r;
            str = str[2..$];
            if (tryParse!(int, wstring)(str, 16, r))
            {
                if (!str.empty)
                    return 0;
                return r;
            }
            else
            {
                return 0;
            }
        }
        if(str.length > 2 && str[0..2] == "&B")
        {
            int r;
            str = str[2..$];
            if (tryParse!(int, wstring)(str, 2, r))
            {
                if (!str.empty)
                    return 0;
                return r;
            }
            else
            {
                return 0;
            }
        }
        double val;
        if(tryParse(str, val) && str.empty)
            return val;
        else
            return 0;
    }
    static Value FLOOR(Value val)
    {
        if (val.isInteger)
        {
            return val;
        }

        return Value(val.doubleValue.floor);
    }
    static Value ROUND(Value val)
    {
        if (val.isInteger)
        {
            return val;
        }

        return Value(val.doubleValue.round);
    }
    static Value CEIL(Value val)
    {
        if (val.isInteger)
        {
            return val;
        }

        return Value(val.doubleValue.ceil);
    }
    static wstring MID(wstring str, int i, int len)
    {
        if(i + len > str.length)
        {
            if(i >= str.length)
            {
                return "";//範囲外で空文字
            }
            return str[i..$];//iがまだ範囲内なら最後まで
        }
        //挙動未定
        return str[i..i + len];
    }
    //INSTRSUSBTLEFT
    static wstring LEFT(wstring str, int len)
    {
        return str[0..len];
    }
    static wstring RIGHT(wstring str, int len)
    {
        return str[$ - len..$];
    }
    static wstring SUBST(wstring str, int i, Value alen, DefaultValue!(Value,false) areplace)
    {
        int len = 1;
        wstring replace = "";
        if(alen.isNumber)
        {
            len = alen.castInteger;
            replace = areplace.castString;
        }
        else
        {
            replace = alen.castString;
            //省略されたらi以降の全文字を置換
            return str[0..i] ~ replace;
        }
        if(str.length <= i + len)
        {
            return str[0..i] ~ replace;
        }
        str.replaceInPlace(i, i + len, replace);
        return str;
    }
    static int INSTR(Value vstart, Value vstr1, DefaultValue!(wstring, false) vstr2)
    {
        int start = 0;
        wstring str1, str2;
        if(!vstr2.isDefault)
        {
            start = vstart.castInteger;
            str1 = vstr1.castString;
            str2 = cast(wstring)vstr2;
        }
        else
        {
            str1 = vstart.castString;
            str2 = vstr1.castString;
        }
        return cast(int)(str1[start..$].indexOf(str2, CaseSensitive.no));
    }
    static int ASC(wstring str)
    {
        if(str.empty)
            throw new IllegalFunctionCall("ASC");
        return cast(int)str[0];
    }
    static wstring STR(double val)
    {
        return val.to!wstring;
    }
    static wstring STR(double val, int digits)
    {
        //formatだとうまくいかない
        if(digits > 63 || digits < 0)
        {
            throw new OutOfRange();
        }
        auto str = val.to!wstring;
        if (str.length >= digits)
            return str;
        wchar[64] str2;
        str2[0..digits - str.length] = ' ';
        str2[digits - str.length..digits] = str;
        return str2[0..digits].to!wstring;
    }
    static wstring HEX(int val, DefaultValue!(int, false) digits)
    {
        import std.format;
        if(digits > 8 || digits < 0)
        {
            throw new OutOfRange();
        }
        FormatSpec!char f;
        f.spec = 'X';
        f.flZero = !digits.isDefault;
        f.width = cast(int)digits;
        auto w = appender!wstring();
        formatValue(w, val, f);
        return cast(immutable)(w.data);
    }
    static void SPSET(PetitComputer p, int id, int defno, DefaultValue!(int, false) V, DefaultValue!(int, false) W, DefaultValue!(int, false) H, DefaultValue!(int, false) ATTR)
    {
        if(!V.isDefault && !W.isDefault)
        {
            int u = defno;
            int v = cast(int)V;
            int w = 16, h = 16, attr = 1;
            if(!ATTR.isDefault)
            {
                w = cast(int)W;
                h = cast(int)H;
                attr = cast(int)ATTR;
            }
            else
            {
                if(!W.isDefault && !H.isDefault)
                {
                    w = cast(int)W;
                    h = cast(int)H;
                }
                if(!W.isDefault && H.isDefault)
                {
                    attr = cast(int)W;
                }
            }
            p.sprite.spset(id, u, v, w, h, cast(SpriteAttr)attr);
            return;
        }
        p.sprite.spset(id, defno);
    }
    static void SPCHR(PetitComputer p, int id, int defno, DefaultValue!(int, false) V, DefaultValue!(int, false) W, DefaultValue!(int, false) H, DefaultValue!(int, false) ATTR)
    {
        if(!V.isDefault && !W.isDefault)
        {
            int u = defno;
            int v = cast(int)V;
            int w = 16, h = 16, attr = 1;
            if(!ATTR.isDefault)
            {
                w = cast(int)W;
                h = cast(int)H;
                attr = cast(int)ATTR;
            }
            else
            {
                if(!W.isDefault && !H.isDefault)
                {
                    w = cast(int)W;
                    h = cast(int)H;
                }
                if(!W.isDefault && H.isDefault)
                {
                    attr = cast(int)W;
                }
            }
            p.sprite.spchr(id, u, v, w, h, cast(SpriteAttr)attr);
            return;
        }
        p.sprite.spchr(id, defno);
    }
    static void SPCHR(PetitComputer p, int id, out int defno)
    {
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPCHR", 1);
        }
        p.sprite.getSpchr(id, defno);
    }
    static void SPCHR(PetitComputer p, int id, out int u, out int v, out int w, out int h, out int attr)
    {
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPCHR", 1);
        }
        SpriteAttr spriteattr;
        p.sprite.getSpchr(id, u, v, w, h, spriteattr);
        attr = cast(int)spriteattr;
    }
    static void SPCHR(PetitComputer p, int id, out int u, out int v)
    {
        int w, h, attr;
        SPCHR(p, id, u, v, w, h , attr);
    }
    static void SPCHR(PetitComputer p, int id, out int u, out int v, out int w, out int h)
    {
        int attr;
        SPCHR(p, id, u, v, w, h , attr);
    }
    static void SPHIDE(PetitComputer p, int id)
    {
        p.sprite.sphide(id);
    }
    static void SPSHOW(PetitComputer p, int id)
    {
        p.sprite.spshow(id);
    }
    static void SPOFS(PetitComputer p, int id, double x, double y, DefaultValue!(int, false) z)
    {
        if(z.isDefault)
        {
            p.sprite.spofs(id, x, y);
        }
        else
        {
            p.sprite.spofs(id, x, y, cast(int)z);
        }
    }
    @StartOptional("z")
    static void SPOFS(PetitComputer p, int id, out double x, out double y, out int z)
    {
        p.sprite.getspofs(id, x, y, z);
    }
    static void SPANIM(PetitComputer p, Value[] va_args)
    {
        //TODO:配列
        auto args = retro(va_args);
        int no = args[0].castInteger;
        double[] animdata;
        if(args[2].isString)
        {
            VM vm = p.vm;
            vm.pushDataIndex();
            vm.restoreData(args[2].castString);
            int keyframe = vm.readData.castInteger;
            auto target = p.sprite.getSpriteAnimTarget(args[1].castString);
            int item = 2;
            if((target & 7) == SpriteAnimTarget.XY || (target & 7) == SpriteAnimTarget.UV) item++;
            animdata = new double[item * keyframe + 1];
            int j;
            for(int i = 0; i < keyframe; i++)
            {
                animdata[j] = vm.readData.castDouble;
                animdata[j + 1] = vm.readData.castDouble;
                if(item == 3)
                    animdata[j + 2] = vm.readData.castDouble;
                j += item;
            }
            if(args.length > 2)
                animdata[j] = args[3].castInteger;
            vm.popDataIndex();
        }
        else
        {
            int i;
            animdata = new double[args.length - 2];
            foreach(a; args[2..$])
            {
                animdata[i++] = a.castDouble;
            }
        }
        if(args[1].isString)
            p.sprite.spanim(no, args[1].castString, animdata);
        if(args[1].isNumber)
            p.sprite.spanim(no, cast(SpriteAnimTarget)(args[1].castInteger), animdata);
    }
    @StartOptional("W")
    static void SPDEF(PetitComputer p, int id, out int U, out int V, out int W, out int H, out int HX, out int HY, out int A)
    {
        p.sprite.getspdef(id, U, V, W, H, HX, HY, A);
    }
    static void SPDEF(PetitComputer p, Value[] va_args2)
    {
        auto va_args = retro(va_args2);
        switch(va_args.length)
        {
            case 0:
                p.sprite.spdef();//初期化
                return;
            case 1://array
                {
                    if(va_args[0].isNumberArray)
                    {
                        writeln("NOTIMPL:SPDEF ARRAY");
                        //return;
                    }
                    if(va_args[0].isString)
                    {
                        VM vm = p.vm;
                        vm.pushDataIndex();
                        vm.restoreData(va_args[0].castString);
                        auto count = vm.readData().castInteger;//読み込むスプライト数
                        int defno = 0;//?
                        for(int i = 0; i < count; i++)
                        {
                            int U = vm.readData().castInteger;
                            int V = vm.readData().castInteger;
                            int W = vm.readData().castInteger;
                            int H = vm.readData().castInteger;
                            int HX = vm.readData().castInteger;
                            int HY = vm.readData().castInteger;
                            int ATTR = vm.readData().castInteger;
                            p.sprite.SPDEFTable[defno] = SpriteDef(U, V, W, H, HX, HY, cast(SpriteAttr)ATTR);
                            defno++;
                        }
                        vm.popDataIndex();
                        return;
                    }
                    throw new IllegalFunctionCall("SPDEF");
                }
            default:
        }
        {
            int defno = va_args[0].castInteger;
            int U = va_args[1].castInteger;
            int V = va_args[2].castInteger;
            int W = 16, H = 16, HX = 0, HY = 0, ATTR = 1;
            if(va_args.length > 3)
            {
                W = va_args[3].castInteger;
            }
            if(va_args.length > 4)
            {
                H = va_args[4].castInteger;
            }
            if(va_args.length > 5)
            {
                HX = va_args[5].castInteger;
            }
            if(va_args.length > 6)
            {
                HY = va_args[6].castInteger;
            }
            if(va_args.length > 7)
            {
                ATTR = va_args[7].castInteger;
            }
            p.sprite.SPDEFTable[defno] = SpriteDef(U, V, W, H, HX, HY, cast(SpriteAttr)ATTR);
        }
    }
    static void SPCLR(PetitComputer p, DefaultValue!(int, false) i)
    {
        if(i.isDefault)
            p.sprite.spclr();
        else
            p.sprite.spclr(cast(int)i);
    }
    static void SPHOME(PetitComputer p, int i, int hx, int hy)
    {
        p.sprite.sphome(i, hx, hy);
    }
    static void SPSCALE(PetitComputer p, int i, double x, double y)
    {
        p.sprite.spscale(i, x, y);
    }
    static void SPROT(PetitComputer p, int i, double rot)
    {
        p.sprite.sprot(i, rot);
    }
    static void SPCOLOR(PetitComputer p, int id, int color)
    {
        p.sprite.spcolor(id, cast(uint)color);
    }
    static void SPLINK(PetitComputer p, int child, int parent)
    {
        p.sprite.splink(child, parent);
    }
    static void SPUNLINK(PetitComputer p, int id)
    {
        p.sprite.spunlink(id);
    }
    static void SPCOL(PetitComputer p, int id, DefaultValue!(int, false) scale)
    {
        scale.setDefaultValue(true);
        p.sprite.spcol(id, cast(bool)scale);
    }
    static void SPCOL(PetitComputer p, int id, DefaultValue!int scale, int mask)
    {
        scale.setDefaultValue(true);
        p.sprite.spcol(id, cast(bool)scale, mask);
    }
    static void SPCOL(PetitComputer p, int id, int x, int y, int w, int h, int scale)
    {
        p.sprite.spcol(id, cast(short)x, cast(short)y, cast(ushort)w, cast(ushort)h, cast(bool)scale, -1);
    }
    static void SPCOL(PetitComputer p, int id, int x, int y, int w, int h, DefaultValue!int scale, int mask)
    {
        scale.setDefaultValue(true);
        p.sprite.spcol(id, cast(short)x, cast(short)y, cast(ushort)w, cast(ushort)h, cast(bool)scale, mask);
    }
    static int SPHITSP(PetitComputer p, int id)
    {
        return p.sprite.sphitsp(id);
    }
    static int SPHITSP(PetitComputer p, int id, int min)
    {
        return p.sprite.sphitsp(id, min, 511);//?
    }
    static int SPHITSP(PetitComputer p, int id, int min, int max)
    {
        return p.sprite.sphitsp(id, min, max);
    }
    static void SPVAR(PetitComputer p, int id, int var, double val)
    {
        p.sprite.spvar(id, var, val);
    }
    static double SPVAR(PetitComputer p, int id, int var)
    {
        return p.sprite.spvar(id, var);
    }
    static int SPCHK(PetitComputer p, int id)
    {
        return p.sprite.spchk(id);
    }
    static void SPPAGE(PetitComputer p, int page)
    {
        if (!p.isValidGraphicPage(page))
        {
            throw new OutOfRange("SPPAGE", 1);
        }
        p.sprite.sppage = page;
    }
    static int SPPAGE(PetitComputer p)
    {
        return p.sprite.sppage;
    }
    static void BGMSTOP(PetitComputer p)
    {
        writeln("NOTIMPL:BGMSTOP");
    }
    static int BGMCHK(PetitComputer p)
    {
        writeln("NOTIMPL:BGMCHK");
        return false;
    }
    static int CHKCHR(PetitComputer p, int x, int y)
    {
        return cast(int)(p.console.console[y][x].character);
    }
    struct FixedBuffer(T, size_t S)
    {
        T[S] buffer = void;
        size_t length;
        void put(T v)
        {
            if (buffer.length <= length)
            {
                throw new StringTooLong("FORMAT$", 2);
            }
            buffer[length++] = v;
        }
    }
    static wstring FORMAT(PetitComputer p, Value[] va_args)
    {
        alias retro!(Value[]) VaArgs;
        auto args = retro(va_args);
        auto format = args[0].castString;
        import std.array : appender;
        import std.format;
        FixedBuffer!(wchar, 1024) buffer;//String too long
        int j = 1;
        for(int i = 0; i < format.length; i++)
        {
            auto f = format[i];
            if(f == '%')
            {
                i = i + 1;
                bool sign = false;//+
                bool left = false;//-
                bool space = false;//' '
                bool zero = false;
                for(; i < format.length; i++)
                {
                    auto c = format[i];
                    if (c == '+')
                    {
                        sign = true;
                    }
                    else if (c == ' ')
                    {
                        space = true;
                    }
                    else if (c == '-')
                    {
                        left = true;
                    }
                    else if (c == '0')
                    {
                        zero = true;
                    }
                    else
                    {
                        break;
                    }
                }
                int d1, d2 = 6;
                bool d2f;
                wstring a1 = format[i..$];
                if (a1[0] >= '0' && a1[0] <= '9')
                {
                    d1 = parse!(int, wstring)(a1);
                }
                if (a1[0] == '.')
                {
                    a1 = a1[1..$];
                    if (a1[0] >= '0' && a1[0] <= '9')
                    {
                        d2 = parse!(int, wstring)(a1);
                        d2f = true;
                    }
                }
                wstring buf;
                FormatSpec!wchar spec;
                switch (a1[0])
                {
                    case 'S', 's':
                        {
                            auto val = args[j].castString;
                            spec.width = d1;
                            spec.flDash = left;
                            spec.flZero = zero;
                            spec.flPlus = sign;
                            spec.flSpace = space;
                            formatValue(&buffer, val, spec);
                            break;
                        }
                    case 'X', 'x':
                        spec.spec = 'X';
                        goto caseInteger;
                    case 'B', 'b':
                        spec.spec = 'b';
                        goto caseInteger;
                    case 'D', 'd':
                        spec.spec = 'd';
                        caseInteger:
                        {
                            auto val = args[j].castInteger;
                            spec.width = d1;
                            if (d2f)
                                spec.precision = d2;
                            spec.flDash = left;
                            spec.flZero = zero;
                            spec.flPlus = sign;
                            spec.flSpace = space;
                            formatValue(&buffer, val, spec);
                            break;
                        }
                    case 'F', 'f':
                        {
                            spec.spec = 'f';
                            auto val = args[j].castDouble;
                            spec.width = d1;
                            if (d2 < 1022)
                            {
                                spec.precision = d2;
                                spec.flDash = left;
                                spec.flZero = zero;
                                spec.flPlus = sign;
                                spec.flSpace = space;
                                formatValue(&buffer, val, spec);
                            }
                            break;
                        }
                    default:
                        throw new IllegalFunctionCall("FORMAT$");
                }
                j++;
                i = 0;
                format = a1;
                continue;
            }
            buffer.put(f);
        }
        wchar[] data = new wchar[buffer.length];
        data[] = buffer.buffer[0..buffer.length];
        return cast(immutable)data;
    }
    static wstring CHR(int code)
    {
        return (cast(wchar)code).to!wstring;
    }
    static pure nothrow double POW(double a1, double a2)
    {
        return a1 ^^ a2;
    }
    static double SQR(double a1)
    {
        if (a1 < 0)
        {
            throw new OutOfRange();
        }
        return sqrt(a1);
    }
    //GalateaTalk利用面倒くさい...
    static void TALK(wstring a1)
    {
    }
    static void BGCLR(PetitComputer p, DefaultValue!(int, false) layer)
    {
        if(layer.isDefault)
        {
            foreach(bg; p.allBG)
            {
                bg.clear;
            }
            return;
        }
        p.getBG(cast(int)layer).clear;
    }
    static void BGSCREEN(PetitComputer p, int layer, int w, int h)
    {
        p.getBG(layer).screen(w, h);
    }
    static void BGOFS(PetitComputer p, int layer, int x, int y, DefaultValue!(int, false) z)
    {
        z.setDefaultValue(p.getBG(layer).offsetz);
        p.getBG(layer).ofs(x, y, cast(int)z);
    }
    static void BGCLIP(PetitComputer p, int layer)
    {
        p.getBG(layer).clip();
    }
    static void BGCLIP(PetitComputer p, int layer, int x, int y, int x2, int y2)
    {
        p.getBG(layer).clip(x, y, x2, y2);
    }
    static void BGPUT(PetitComputer p, int layer, int x, int y, int screendata)
    {
        p.getBG(layer).put(x, y, screendata);
    }
    static void BGHOME(PetitComputer p, int layer, int x, int y)
    {
        p.getBG(layer).home(x, y);
    }
    static void BGSCALE(PetitComputer p, int layer, double x, double y)
    {
        p.getBG(layer).scale(x, y);
    }
    static void BGROT(PetitComputer p, int layer, double rot)
    {
        p.getBG(layer).rot(rot);
    }
    static void BGFILL(PetitComputer p, int layer, int x, int y, int x2, int y2, int screendata)
    {
        p.getBG(layer).fill(x, y, x2, y2, screendata);
    }
    static void BGPAGE(PetitComputer p, int page)
    {
        if (!p.isValidGraphicPage(page))
        {
            throw new OutOfRange("BGPAGE", 1);
        }
        p.bgpage = page;
    }
    static int BGPAGE(PetitComputer p)
    {
        return p.bgpage;
    }
    static void BGSHOW(PetitComputer p, int layer)
    {
        p.getBG(layer).show = true;
    }
    static void BGHIDE(PetitComputer p, int layer)
    {
        p.getBG(layer).show = false;
    }
    static int BGGET(PetitComputer p, int layer, int x, int y)
    {
        return BGGET(p, layer, x, y, 0);
    }
    static int BGGET(PetitComputer p, int layer, int x, int y, int flag)
    {
        return p.getBG(layer).get(x, y, flag);
    }
    static void EFCON()
    {
    }
    static void EFCOFF()
    {
    }
    static void EFCSET(Value[])
    {
    }
    static void EFCWET(Value[])
    {
    }
    static void COPY(PetitComputer p, Value[] rawargs)
    {
        auto args = retro(rawargs);
        //文字列はリテラル渡すとType mismatch
        if(args.length > 5 || args.length < 2 || !args[0].isArray)
        {
            throw new IllegalFunctionCall("COPY");
        }
        //COPY string, string->文字列COPY
        //COPY array, string->DATA COPY
        Value dst = args[0];
        int dstoffset = 0;
        int srcoffset = 0;
        int len = dst.length;//省略時はコピー元の末尾まで
        if(args[1].isString && !args[0].isString)
        {
            //DATAから
            VM vm = p.vm;
            vm.restoreData(args[1].castString);
            for(int i = 0; i < len; i++)
            {
                Value data = vm.readData();
                dst[dstoffset++] = data;
            }
            return;
        }
        throw new IllegalFunctionCall("COPY (Not implemented error)");
    }
    @BasicName("LOAD")
    static Value LOAD1(PetitComputer p, wstring name, DefaultValue!(int, false) flag)
    {
        import otya.smilebasic.project;
        flag.setDefaultValue(0);
        auto type = Projects.splitResourceName(name);
        wstring txt;
        wstring resname = type[0];
        wstring projectname = type[1];
        wstring filename = type[2];
        if (!Projects.isValidFileName(filename))
        {
            throw new IllegalFunctionCall("LOAD");
        }
        if(projectname != "" && projectname.toUpper != "SYS")
        {
            throw new IllegalFunctionCall("LOAD");
        }
        if(projectname == "")
        {
            projectname = p.currentProject;
        }
        if(resname == "TXT")
        {
            if(p.project.loadFile(projectname, resname, filename, txt))
            {
                return Value(txt);
            }
            //not exist
            return Value("");
        }
        throw new IllegalFunctionCall("LOAD");
    }
    @BasicName("LOAD")
    static void LOAD2(PetitComputer p, wstring name, DefaultValue!(int, false) flag)
    {
        import otya.smilebasic.project;
        flag.setDefaultValue(0);
        auto type = Projects.splitResourceName(name);
        wstring txt;
        wstring resname = type[0].toUpper;
        wstring projectname = type[1];
        wstring filename = type[2];
        if (!Projects.isValidFileName(filename))
        {
            throw new IllegalFunctionCall("LOAD");
        }
        if(projectname != "" && projectname.toUpper != "SYS")
        {
            throw new IllegalFunctionCall("LOAD");
        }
        if(projectname == "")
        {
            projectname = p.currentProject;
        }
        if(resname == "" || resname.indexOf("PRG") == 0)
        {
            int lot;
            if(resname != "" && resname != "PRG")
            {
                auto num = resname[3..$];
                lot = num.to!int;
            }
            if(!p.project.loadFile(projectname, "TXT", filename, txt))
            {
                //not exist
                return;
            }
            p.slot[lot].load(txt);
            return;
        }
        if(resname.indexOf("GRP") == 0)
        {
            throw new IllegalFunctionCall("NOTIMPL:LOAD GRP");
        }
        throw new IllegalFunctionCall("LOAD");
    }
    static void LOAD(wstring name, Value arr, DefaultValue!(int, false) flag)
    {
        flag.setDefaultValue(0);
        throw new IllegalFunctionCall("NOTIMPL:LOAD");
    }
    static void PROJECT(PetitComputer p, wstring name)
    {
        //DirectMode only
        if(p.isRunningDirectMode)
        {
            if(!p.project.isValidProjectName(name))
            {
                throw new IllegalFunctionCall("PROJECT");
            }
            p.currentProject = name;
            return;
        }
        throw new CantUseInProgram("PROJECT");
    }
    static void PROJECT(PetitComputer p, out wstring name)
    {
        name = p.currentProject;
    }
    //FILES TYPE$
    //((TXT|DAT):)?\w+/?
    static void FILES(PetitComputer p, DefaultValue!(wstring, false) name)
    {
        import otya.smilebasic.project;
        if(name.isDefault)
        {
            name.setDefaultValue(p.currentProject);
        }
        auto t = Projects.splitResourceName(name.value);
        auto res = t[0];
        if(t[1].length && t[2].length)
        {
            throw new IllegalFunctionCall("FILES");
        }
        if(t[2].length && name.value.indexOf("/") != -1)
        {
            //"TXT:A":OK
            //"TXT:A/":OK
            //"TXT:/A":X
            //"TXT:A/A":X
            throw new IllegalFunctionCall("FILES");
        }
        auto project = t[1].length ? t[1] : t[2];
        //project:.->hidden project
        //project:/->project list
        auto l = p.project.getFileList(project, res);
        p.console.print(res, "\t", project, "\n");
        foreach(i; l)
        {
            p.console.print(i, "\n");
        }
    }
    static void FILES(PetitComputer p, wstring name, Value[] array)
    {
        writeln("NOTIMPL");
    }
    static void ACLS(PetitComputer p)
    {
        p.console.cls;
        SPCLR(p, DefaultValue!(int, false)(true));
        BGCLR(p, DefaultValue!(int, false)(true));
        GCLS(p, DefaultValue!(int, false)(true));
    }
    static int CHKCALL(PetitComputer p, wstring func)
    {
        func = func.toUpper;
        return (func in p.vm.currentSlot.functions) != null || (func in otya.smilebasic.builtinfunctions.BuiltinFunction.builtinFunctions) != null;
    }
    static int CHKLABEL(PetitComputer p, wstring label)
    {
        label = label.toUpper;
        return (label in p.vm.currentSlot.globalLabel) != null;
    }
    static wstring INKEY(PetitComputer p)
    {
        return p.inkey();
    }
    static auto getSortArgument(Value[] arg, out int start, out int count)
    {
        auto args = retro(arg);
        //引数何も指定しなくても実行前エラーは出ない
        if (args.length < 1)
            throw new IllegalFunctionCall("");
        if (args.length > 2)
        {
            if (args[0].isNumber || args[1].isNumber)
            {
                if (args[0].isNumber && args[1].isNumber)
                {
                    start = args[0].castInteger();
                    count = args[1].castInteger();
                    args = args[2..$];
                }
                else
                {
                    throw new IllegalFunctionCall("");
                }
            }
            else
            {
                start = 0;
                count = args[0].length;
            }
        }
        else
        {
            start = 0;
            count = args[0].length;
        }
        if (args.length > 8)
            throw new IllegalFunctionCall("");
        foreach (ref a; args)
        {
            if (a.isString || !a.isArray)
            {
                throw new TypeMismatch();
            }
        }
        return args;
    }
    struct wrappeeer
    {
        Value value;
        union
        {
            int[] integerArray;
            double[] doubleArray;
            wstring[] stringArray;
        }
        this(ref Value v)
        {
            value = v;
            if (value.type == ValueType.IntegerArray)
            {
                integerArray = value.integerArray.array;
            }
            if (value.type == ValueType.DoubleArray)
            {
                doubleArray = value.doubleArray.array;
            }
            if (value.type == ValueType.StringArray)
            {
                stringArray = value.stringArray.array;
            }
        }
        private void slice(int x, int y)
        {
            if (value.type == ValueType.IntegerArray)
            {
                integerArray = integerArray[x..y];
            }
            if (value.type == ValueType.DoubleArray)
            {
                doubleArray = doubleArray[x..y];
            }
            if (value.type == ValueType.StringArray)
            {
                stringArray = stringArray[x..y];
            }
        }
        size_t length()
        {
            if (value.type == ValueType.IntegerArray)
            {
                return integerArray.length;
            }
            if (value.type == ValueType.DoubleArray)
            {
                return doubleArray.length;
            }
            if (value.type == ValueType.StringArray)
            {
                return stringArray.length;
            }
            throw new TypeMismatch();
        }
        bool empty()
        {
            if (value.type == ValueType.IntegerArray)
            {
                return integerArray.empty;
            }
            if (value.type == ValueType.DoubleArray)
            {
                return doubleArray.empty;
            }
            if (value.type == ValueType.StringArray)
            {
                return stringArray.empty;
            }
            throw new TypeMismatch();
        }
        void popFront()
        {
            if (value.type == ValueType.IntegerArray)
            {
                integerArray.popFront;
            }
            if (value.type == ValueType.DoubleArray)
            {
                doubleArray.popFront;
            }
            if (value.type == ValueType.StringArray)
            {
                stringArray.popFront;
            }
        }
        void front(Value v)
        {
            if (value.type == ValueType.IntegerArray)
            {
                integerArray.front = v.castInteger;
            }
            if (value.type == ValueType.DoubleArray)
            {
                doubleArray.front = v.castDouble;
            }
            if (value.type == ValueType.StringArray)
            {
                stringArray.front = v.castString;
            }
        }
        void popBack()
        {
            if (value.type == ValueType.IntegerArray)
            {
                integerArray.popBack;
            }
            if (value.type == ValueType.DoubleArray)
            {
                doubleArray.popBack;
            }
            if (value.type == ValueType.StringArray)
            {
                stringArray.popBack;
            }
        }
        Value back()
        {
            if (value.type == ValueType.IntegerArray)
            {
                return Value(integerArray.back);
            }
            if (value.type == ValueType.DoubleArray)
            {
                return Value(doubleArray.back);
            }
            if (value.type == ValueType.StringArray)
            {
                return Value(stringArray.back);
            }
            throw new TypeMismatch();
        }
        void back(Value v)
        {
            if (value.type == ValueType.IntegerArray)
            {
                integerArray.back = v.castInteger;
            }
            if (value.type == ValueType.DoubleArray)
            {
                doubleArray.back = v.castDouble;
            }
            if (value.type == ValueType.StringArray)
            {
                stringArray.back = v.castString;
            }
        }
        typeof(this) save()
        {
            return this;
        }
        Value front()
        {
            if (value.type == ValueType.IntegerArray)
            {
                return Value(integerArray.front);
            }
            if (value.type == ValueType.DoubleArray)
            {
                return Value(doubleArray.front);
            }
            if (value.type == ValueType.StringArray)
            {
                return Value(stringArray.front);
            }
            throw new TypeMismatch();
        }
        void opIndexAssign(Value v, size_t index)
        {
            if (value.type == ValueType.IntegerArray)
            {
                integerArray[index] = v.castInteger;
                return;
            }
            if (value.type == ValueType.DoubleArray)
            {
                doubleArray[index] = v.castDouble;
                return;
            }
            if (value.type == ValueType.StringArray)
            {
                stringArray[index] = v.castString;
                return;
            }
            throw new TypeMismatch();
        }
        Value opIndex(size_t index)
        {
            if (value.type == ValueType.IntegerArray)
            {
                return Value(integerArray[index]);
            }
            if (value.type == ValueType.DoubleArray)
            {
                return Value(doubleArray[index]);
            }
            if (value.type == ValueType.StringArray)
            {
                return Value(stringArray[index]);
            }
            throw new TypeMismatch();
        }
        wrappeeer opSlice(size_t x, size_t y)
        {
            wrappeeer aa = wrappeeer(value);
            if (value.type == ValueType.IntegerArray)
            {
                aa.integerArray = integerArray[x..y];
            }
            if (value.type == ValueType.DoubleArray)
            {
                aa.doubleArray = doubleArray[x..y];
            }
            if (value.type == ValueType.StringArray)
            {
                aa.stringArray = stringArray[x..y];
            }
            return aa;
        }
    }
    static string sortGenerator(int count, string less)()
    {
        string buf = "switch(args.length){";
        string args = "";
        for (int i = 0; i < count; i++)
        {
            args ~= ",wrappeeer(args[" ~ (i + 1).to!string ~ "])[start..start + count]";
            buf ~= "case " ~ (i + 2).to!string ~ ":";
            buf ~= "if(args[0].type==ValueType.IntegerArray){sort!(" ~ less ~ ", SwapStrategy.stable)(zip(iarray" ~ args ~ "));}";
            buf ~= "else if(args[0].type==ValueType.DoubleArray){sort!(" ~ less ~ ", SwapStrategy.stable)(zip(darray" ~ args ~ "));}";
            buf ~= "else if(args[0].type==ValueType.StringArray){sort!(" ~ less ~ ", SwapStrategy.stable)(zip(sarray" ~ args ~ "));}";
            buf ~= "break;";
        }
        buf ~= "default:}";
        return buf;
    }
    //もう少しまともな実装できそう
    static void SORT(Value[] arg)
    {
        import std.algorithm.sorting;
        import std.range;
        int start, count;
        auto args = getSortArgument(arg, start, count);

        int[] iarray;
        double[] darray;
        wstring[] sarray;
        if (args[0].type == ValueType.IntegerArray)
        {
            iarray = args[0].integerArray.array[start..start + count];
        }
        if (args[0].type == ValueType.DoubleArray)
        {
            darray = args[0].doubleArray.array[start..start + count];
        }
        if (args[0].type == ValueType.StringArray)
        {
            sarray = args[0].stringArray.array[start..start + count];
        }
        if (args.length > 1)
        {
            mixin(sortGenerator!(8, "\"a[0]<b[0]\""));
            /*
            if (args[0].type == ValueType.IntegerArray)
            {
                sort!("a[0] < b[0]", SwapStrategy.stable)(zip(args[0].integerArray.array, wrappeeer(args[1])));
            }
            if (args[0].type == ValueType.DoubleArray)
            {
                sort!("a[0] < b[0]", SwapStrategy.stable)(zip(args[0].doubleArray.array, wrappeeer(args[1])));
            }
            if (args[0].type == ValueType.StringArray)
            {
                sort!("a[0] < b[0]", SwapStrategy.stable)(zip(args[0].stringArray.array, wrappeeer(args[1])));
            }*/
        }
        else
        {
            if (args[0].type == ValueType.IntegerArray)
            {
                sort!("a < b", SwapStrategy.stable)(iarray);
            }
            if (args[0].type == ValueType.DoubleArray)
            {
                sort!("a < b", SwapStrategy.stable)(darray);
            }
            if (args[0].type == ValueType.StringArray)
            {
                sort!("a < b", SwapStrategy.stable)(sarray);
            }
        }
    }
    static void RSORT(Value[] arg)
    {
        import std.algorithm.sorting;
        import std.range;
        int start, count;
        auto args = getSortArgument(arg, start, count);

        int[] iarray;
        double[] darray;
        wstring[] sarray;
        if (args[0].type == ValueType.IntegerArray)
        {
            iarray = args[0].integerArray.array[start..start + count];
        }
        if (args[0].type == ValueType.DoubleArray)
        {
            darray = args[0].doubleArray.array[start..start + count];
        }
        if (args[0].type == ValueType.StringArray)
        {
            sarray = args[0].stringArray.array[start..start + count];
        }
        if (args.length > 1)
        {
            mixin(sortGenerator!(8, "\"a[0]>b[0]\""));
        }
        else
        {
            if (args[0].type == ValueType.IntegerArray)
            {
                sort!("a > b", SwapStrategy.stable)(iarray);
            }
            if (args[0].type == ValueType.DoubleArray)
            {
                sort!("a > b", SwapStrategy.stable)(darray);
            }
            if (args[0].type == ValueType.StringArray)
            {
                sort!("a > b", SwapStrategy.stable)(sarray);
            }
        }
    }
    static double MAX(Value array)
    {
        import std.algorithm.searching;
        if (array.type == ValueType.IntegerArray)
        {
            return minPos!"a > b"(array.integerArray.array)[0];
        }
        if (array.type == ValueType.DoubleArray)
        {
            return minPos!"a > b"(array.doubleArray.array)[0];
        }
        throw new TypeMismatch();
    }
    static double MAX(Value[] args)
    {
        import std.algorithm.searching;
        if (args.length == 0)
        {
            throw new IllegalFunctionCall("MAX");
        }
        return minPos!"a.castDouble > b.castDouble"(args)[0].castDouble;
    }
    static double MIN(Value array)
    {
        import std.algorithm.searching;
        if (array.type == ValueType.IntegerArray)
        {
            return minPos!"a < b"(array.integerArray.array)[0];
        }
        if (array.type == ValueType.DoubleArray)
        {
            return minPos!"a < b"(array.doubleArray.array)[0];
        }
        throw new TypeMismatch();
    }
    static double MIN(Value[] args)
    {
        import std.algorithm.searching;
        if (args.length == 0)
        {
            throw new IllegalFunctionCall("MIN");
        }
        return minPos!"a.castDouble < b.castDouble"(args)[0].castDouble;
    }
    //MAX(2,0)*&H7FFFFFFFF!=MAX(2,0,0)*&H7FFFFFFFF
    static Value MAX(Value a1, Value a2)
    {
        if (a1.type == ValueType.Integer && a2.type == ValueType.Integer)
        {
            return Value(a1.integerValue > a2.integerValue ? a1.integerValue : a2.integerValue);
        }
        return Value(a1.castDouble > a2.castDouble ? a1.castDouble : a2.castDouble);
    }
    static Value MIN(Value a1, Value a2)
    {
        if (a1.type == ValueType.Integer && a2.type == ValueType.Integer)
        {
            return Value(a1.integerValue < a2.integerValue ? a1.integerValue : a2.integerValue);
        }
        return Value(a1.castDouble < a2.castDouble ? a1.castDouble : a2.castDouble);
    }
    static pure nothrow @nogc @safe double EXP()
    {
        return std.math.E;
    }
    static pure nothrow @nogc @safe double EXP(double d)
    {
        return std.math.exp(d);
    }
    static double LOG(double a)
    {
        if (a <= 0)
        {
            throw new OutOfRange();
        }
        return std.math.log(a);
    }
    static double LOG(double a, double b)
    {
        if (a <= 0)
        {
            throw new OutOfRange();
        }
        if (b <= 1)
        {
            throw new OutOfRange();
        }
        return std.math.log(a) / std.math.log(b);
    }
    //alias void function(PetitComputer, Value[], Value[]) BuiltinFunc;
    static BuiltinFunctions[wstring] builtinFunctions;
    static wstring getBasicName(BFD)(const wstring def)
    {
        enum attr = __traits(getAttributes, __traits(getOverloads, BFD.C_, BFD.N)[BFD.I_]);
        foreach(i; attr)
        {
            static if(__traits(compiles, i.naame))
            {
                return i.naame;
            }
        }
        return def;
    }

    static this()
    {
        foreach(name; __traits(derivedMembers, BuiltinFunction))
        {
            //writeln(name);
            static if(/*__traits(isStaticFunction, __traits(getMember, BuiltinFunction, name)) && */name[0].isUpper)
            {
                foreach(i, F; __traits(getOverloads, BuiltinFunction, name))
                {
                    //pragma(msg, AddFunc!(BuiltinFunction, name));
                    wstring suffix = "";
                    if(is(ReturnType!(__traits(getMember, BuiltinFunction, name)) == wstring))
                    {
                        suffix = "$";
                    }
                    alias BFD = BuiltinFunctionData!(BuiltinFunction, name, i);
                    wstring name2 = getBasicName!BFD(name ~ suffix);
                    auto func = builtinFunctions.get(name2, null);
                    pragma(msg, AddFunc!BFD);
                    auto f = new BuiltinFunction(
                                                 GetFunctionParamType!(BFD),
                                                 GetFunctionReturnType!(BFD),
                                                 mixin(AddFunc!(BFD)),
                                                 GetStartSkip!(BFD),
                                                 IsVariadic!(BFD),
                                                 name,
                                                 GetOutStartSkip!(BFD)
                                                 );
                    if(func)
                    {
                        builtinFunctions[name2].addFunction(f);
                    }
                    else
                    {
                        builtinFunctions[name2] = new BuiltinFunctions(f);
                    }
                    //writeln(AddFunc!(BuiltinFunction, name));
                }
            }
        }
    }

}
template GetOutStartSkip(BFD)
{
    static if(__traits(getAttributes, __traits(getOverloads, BFD.C_, BFD.N)[BFD.I_]).length == 1 &&
              is(typeof(__traits(getAttributes, __traits(getOverloads, BFD.C_, BFD.N)[BFD.I_])[0]) == StartOptional))
    {
        enum so = __traits(getAttributes, __traits(getOverloads, BFD.C_, BFD.N)[BFD.I_])[0];
        int GetOutStartSkip()
        {
            int k;
            foreach (j, i; ParameterIdentifierTuple!(__traits(getOverloads, BFD.C_, BFD.N)[BFD.I_]))
            {
                if(i == so.name)
                {
                    return k;
                }
                else if(BFD.ParameterStorageClass[j] & ParameterStorageClass.out_)
                {
                    k++;
                }
            }
            return 0;
        }
    }
    else
    {
        int GetOutStartSkip()
        {
            return 0;
        }
    }
}
template GetStartSkip(BFD)
{
    private template SkipSkip(int I, P...)
    {
        static if(P.length <= I)
        {
            enum SkipSkip = I - is(P[0] == PetitComputer);
        }
        else static if(BFD.ParameterStorageClass[I] & ParameterStorageClass.out_)
        {
            enum SkipSkip = I - is(P[0] : PetitComputer);
        }
        else static if(is(P[I] == DefaultValue!(int, false)))
        {
            enum SkipSkip = I - is(P[0] : PetitComputer);
        }
        else static if(is(P[I] == DefaultValue!(double, false)))
        {
            enum SkipSkip = I - is(P[0] : PetitComputer);
        }
        else static if(is(P[I] == DefaultValue!(wstring, false)))
        {
            enum SkipSkip = I - is(P[0] : PetitComputer);
        }
        else static if(is(P[I] == DefaultValue!(Value, false)))
        {
            enum SkipSkip = I - is(P[0] : PetitComputer);
        }
        else
        {
            enum SkipSkip = SkipSkip!(I + 1, P);
        }
    }
    enum GetStartSkip = SkipSkip!(0, BFD.ParameterType);
}
template GetBuiltinFunctionArgment(P...)
{
    static if(is(P[0] == double))
    {
        const string arg = "ValueType.Double, false";
    }
    else static if(is(P[0] == int))
    {
        const string arg = "ValueType.Integer, false";
    }
    else static if(is(P[0] == wstring))
    {
        const string arg = "ValueType.String, false";
    }
    else static if(is(P[0] == DefaultValue!int))
    {
        const string arg = "ValueType.Integer, true";
    }
    else static if(is(P[0] == DefaultValue!(int, false)))
    {
        const string arg = "ValueType.Integer, true";
    }
    else static if(is(P[0] == DefaultValue!double))
    {
        const string arg = "ValueType.Double, true";
    }
    else static if(is(P[0] == DefaultValue!(double, false)))
    {
        const string arg = "ValueType.Double, true";
    }
    else static if(is(P[0] == DefaultValue!(wstring)))
    {
        const string arg = "ValueType.String, false";
    }
    else static if(is(P[0] == DefaultValue!(wstring, false)))
    {
        const string arg = "ValueType.String, true";
    }
    else static if(is(P[0] == Value[]))
    {
        const string arg = "";
    }
    else static if(is(P[0] == DefaultValue!(Value)) || is(P[0] == Value))
    {
        const string arg = "ValueType.Void, false";
    }
    else static if(is(P[0] == DefaultValue!(Value, false)))
    {
        const string arg = "ValueType.Void, true";
    }
    else static if(is(P[0] == void))
    {
        const string arg = "";
    }
    else
    {
        static assert(false, "Invalid type");
    }
    static if(is(P[0] == void))
    {
        enum GetBuiltinFunctionArgment = "";
    }
    else
    {
        enum GetBuiltinFunctionArgment = "BuiltinFunctionArgument(" ~ arg ~ ")";
    }
}
template BuiltinFunctionData(C, string NAME, int I)
{
    //struct BuiltinFunctionData
    //{
        //enum P = ParameterStorageClassTuple!(__traits(getOverloads, C, N)[I]);
    struct BuiltinFunctionData
    {
        alias P = std.traits.ParameterStorageClassTuple!(__traits(getOverloads, C, NAME)[I]);
        alias T = std.traits.ParameterTypeTuple!(__traits(getOverloads, C, NAME)[I]);
        alias R = std.traits.ReturnType!(__traits(getOverloads, C, NAME)[I]);
        alias ParameterStorageClass = std.traits.ParameterStorageClassTuple!(__traits(getOverloads, C, NAME)[I]);
        alias ParameterType = std.traits.ParameterTypeTuple!(__traits(getOverloads, C, NAME)[I]);
        alias ReturnType = std.traits.ReturnType!(__traits(getOverloads, C, NAME)[I]);
        enum F = &__traits(getOverloads, C, NAME)[I];
        alias N = NAME;
        alias C_ = C;
        alias I_ = I;
    }
}
template GetOutArgment(C, string N)
{
    alias T = ParameterTypeTuple!(__traits(getMember, C, N));
    string GetOutArgment2()
    {
        string arg = "";
        foreach(i, J; T)
        {
            enum P = ParameterStorageClassTuple!(__traits(getMember, C, N))[i];
            static if(P & ParameterStorageClass.out_)
            {
                arg ~= GetBuiltinFunctionArgment!(J) ~ ",";
            }
        }
        return arg;
    }
    enum GetOutArgment = GetOutArgment2();
}
template GetOutArgment2(BFD)
{
    alias T = BFD.T;
    string GetOutArgment22()
    {
        string arg = "";
        foreach(i, J; T)
        {
            //enum P = ParameterStorageClassTuple!(__traits(getMember, C, N))[i];
            static if(BFD.P[i] & ParameterStorageClass.out_)
            {
                arg ~= GetBuiltinFunctionArgment!(J) ~ ",";
            }
        }
        return arg;
    }
    enum GetOutArgment2 = GetOutArgment22();
}
//template GetOutArgment2(T2)
//{
//}
template GetFunctionReturnType(BFD)
{
    static if(is(BFD.R == void))
    {
        enum GetFunctionReturnType = 
           mixin("[" ~ GetOutArgment2!(BFD) ~ "]");
    }
    else
    {
        enum GetFunctionReturnType = 
           mixin("[" ~ GetBuiltinFunctionArgment!(BFD.R) ~ "]");
    }
}
template AddFunc(BFD)
{
    static if(is(BFD.ReturnType == double) || is(BFD.ReturnType == int))
    {
        const string AddFunc = "function void(PetitComputer p, Value[] arg, Value[] ret){if(ret.length != 1){throw new IllegalFunctionCall(\"" ~ BFD.N ~ "\");}ret[0] = Value(" ~ BFD.N ~ "(" ~
            AddFuncArg!(/*ParameterTypeTuple!(__traits(getMember, T, N)).length*/GetArgumentCount!(BFD) - 1, 0, 0, 0, BFD,
                         BFD.ParameterType) ~ "));}";
    }
    else static if(is(BFD.ReturnType == void))
    {
        //pragma(msg, GetArgumentCount!(T,N));
        const string AddFunc = "function void(PetitComputer p, Value[] arg, Value[] ret){/*if(ret.length != 0){throw new IllegalFunctionCall(\"" ~ BFD.N ~ "\");}*/" ~ OutArgsInit!(BFD) ~ BFD.N ~ "(" ~
            AddFuncArg!(/*ParameterTypeTuple!(__traits(getMember, T, N)).length*/GetArgumentCount!(BFD) - 1, 0, 0, 0, BFD,
                        BFD.ParameterType) ~ ");}";
    }
    else static if(is(BFD.ReturnType == wstring))
    {
        const string AddFunc = "function void(PetitComputer p, Value[] arg, Value[] ret){if(ret.length != 1){throw new IllegalFunctionCall(\"" ~ BFD.N ~ "\");}ret[0] = Value(" ~ BFD.N ~ "(" ~
            AddFuncArg!(/*ParameterTypeTuple!(__traits(getMember, T, N)).length*/GetArgumentCount!(BFD) - 1, 0, 0, 0, BFD,
                        BFD.ParameterType) ~ "));}";
    }
    else static if(is(BFD.ReturnType == Value))
    {
        const string AddFunc = "function void(PetitComputer p, Value[] arg, Value[] ret){if(ret.length != 1){throw new IllegalFunctionCall(\"" ~ BFD.N ~ "\");}ret[0] = " ~ BFD.N ~ "(" ~
            AddFuncArg!(/*ParameterTypeTuple!(__traits(getMember, T, N)).length*/GetArgumentCount!(BFD) - 1, 0, 0, 0, BFD,
                        BFD.ParameterType) ~ ");}";
    }
    else
    {
        const string AddFunc = "";
        static assert(false, "Invalid type");
    }
}
DefaultValue!int fromIntToDefault(Value v)
{
    if(v.isNumber)
        return DefaultValue!int(v.castInteger());
    else
        return DefaultValue!int(true);
}
DefaultValue!(int, false) fromIntToSkip(Value v)
{
    if(v.isNumber)
        return DefaultValue!(int, false)(v.castInteger());
    else
        return DefaultValue!(int, false)(true);
}
DefaultValue!double fromDoubleToDefault(Value v)
{
    if(v.isNumber)
        return DefaultValue!double(v.castDouble());
    else
        return DefaultValue!double(true);
}
DefaultValue!(double, false) fromDoubleToSkip(Value v)
{
    if(v.isNumber)
        return DefaultValue!(double, false)(v.castDouble());
    else
        return DefaultValue!(double, false)(true);
}
DefaultValue!wstring fromStringToDefault(Value v)
{
    if(v.type == ValueType.String)
        return DefaultValue!wstring(v.castString());
    else
        return DefaultValue!wstring(true);
}
DefaultValue!(wstring, false) fromStringToSkip(Value v)
{
    if(v.type == ValueType.String)
        return DefaultValue!(wstring, false)(v.castString());
    else
        return DefaultValue!(wstring, false)(true);
}
DefaultValue!Value fromValueToDefault(Value v)
{
    if(v.type != ValueType.Void)
        return DefaultValue!Value(v);
    else
        return DefaultValue!Value(true);
}
DefaultValue!(Value, false) fromValueToSkip(Value v)
{
    if(v.type != ValueType.Void)
        return DefaultValue!(Value, false)(v);
    else
        return DefaultValue!(Value, false)(true);
}
template GetFunctionParamType(BFD)
{
    enum GetFunctionParamType = mixin("[" ~ Array!(0, BFD.T) ~ "]");
    private template Array(int I, P...)
    {
        static if(P.length == 0)
        {
            const string arg = "";
            enum Array = "";
        }
        else static if(BFD.ParameterStorageClass[I] & ParameterStorageClass.out_)
        {
            static if(1 == P.length && !is(P[0] == PetitComputer))
            {
                enum Array = "";
            }
            else static if(!is(P[0] == PetitComputer))
            {
                enum Array = Array!(I + 1, P[1..$]);
            }
        }
        else
        {
            static if(is(P[0] == double))
            {
                const string arg = "ValueType.Double, false";
            }
            else static if(is(P[0] == int))
            {
                const string arg = "ValueType.Integer, false";
            }
            else static if(is(P[0] == wstring))
            {
                const string arg = "ValueType.String, false";
            }
            else static if(is(P[0] == DefaultValue!int))
            {
                const string arg = "ValueType.Integer, true";
            }
            else static if(is(P[0] == DefaultValue!(int, false)))
            {
                const string arg = "ValueType.Integer, true";
            }
            else static if(is(P[0] == DefaultValue!double))
            {
                const string arg = "ValueType.Double, true";
            }
            else static if(is(P[0] == DefaultValue!(double, false)))
            {
                const string arg = "ValueType.Double, true";
            }
            else static if(is(P[0] == DefaultValue!(wstring)))
            {
                const string arg = "ValueType.String, false";
            }
            else static if(is(P[0] == DefaultValue!(wstring, false)))
            {
                const string arg = "ValueType.String, true";
            }
            else static if(is(P[0] == Value[]))
            {
                const string arg = "";
            }
            else static if(is(P[0] == DefaultValue!(Value)) || is(P[0] == Value))
            {
                const string arg = "ValueType.Void, false";
            }
            else static if(is(P[0] == DefaultValue!(Value, false)))
            {
                const string arg = "ValueType.Void, true";
            }
            else static if(is(P[0] == PetitComputer))
            {
                static if(P.length != 0)
                {
                    enum Array = Array!(I + 1, P[1..$]);
                }
                else
                {
                    enum Array = "";
                }
            }
            static if(1 == P.length && !is(P[0] == PetitComputer))
            {
                enum Array = "BuiltinFunctionArgument(" ~ arg ~ ")";
            }
            else static if(!is(P[0] == PetitComputer))
            {
                enum Array = "BuiltinFunctionArgument(" ~ arg ~ ")," ~ Array!(I + 1, P[1..$]);
            }
        }
    }
}
template AddFuncArg(int L, int N, int M, int O, BFD, P...)
{
    enum I = L - N;
    static if(BFD.ParameterStorageClass.length <= M)
    {
        const string AddFuncArg = "";
    }
    else
    {
        enum storage = BFD.ParameterStorageClass[M];
        static if(is(P[0] == double))
        {
            static if(storage & ParameterStorageClass.out_)
            {
                enum add = 0;
                enum outadd = 1;
                const string arg = "ret[" ~ O.to!string ~ "].doubleValue";
            }
            else
            {
                enum add = 1;
                enum outadd = 0;
                const string arg = "arg[" ~ I.to!string ~ "].castDouble";
            }
        }
        else static if(is(P[0] == PetitComputer))
        {
            enum add = 0;
            enum outadd = 0;
            const string arg = "p";
        }
        else static if(is(P[0] == int))
        {
            static if(storage & ParameterStorageClass.out_)
            {
                enum add = 0;
                enum outadd = 1;
                const string arg = "ret[" ~ O.to!string ~ "].integerValue";
            }
            else
            {
                enum add = 1;
                enum outadd = 0;
                const string arg = "arg[" ~ I.to!string ~ "].castInteger";
            }
        }
        else static if(is(P[0] == wstring))
        {
            static if(storage & ParameterStorageClass.out_)
            {
                enum add = 0;
                enum outadd = 1;
                const string arg = "ret[" ~ O.to!string ~ "].stringValue";
            }
            else
            {
                enum add = 1;
                enum outadd = 0;
                const string arg = "arg[" ~ I.to!string ~ "].castString";
            }
        }
        else static if(is(P[0] == DefaultValue!int))
        {
            static if(storage & ParameterStorageClass.out_)
            {
                enum add = 0;
                enum outadd = 1;
                const string arg = "ret[" ~ O.to!string ~ "].integerValue";
            }
            else
            {
                enum add = 1;
                enum outadd = 0;
                const string arg = "fromIntToDefault(arg[" ~ I.to!string ~ "])";
            }
        }
        else static if(is(P[0] == DefaultValue!(int, false)))
        {
            enum add = 1;
            enum outadd = 0;
            const string arg = "fromIntToSkip(arg[" ~ I.to!string ~ "])";
        }
        else static if(is(P[0] == DefaultValue!double))
        {
            enum add = 1;
            enum outadd = 0;
            const string arg = "fromDoubleToDefault(arg[" ~ I.to!string ~ "])";
        }
        else static if(is(P[0] == DefaultValue!(double, false)))
        {
            enum add = 1;
            enum outadd = 0;
            const string arg = "fromDoubleToSkip(arg[" ~ I.to!string ~ "])";
        }
        else static if(is(P[0] == DefaultValue!wstring))
        {
            enum add = 1;
            enum outadd = 0;
            const string arg = "fromStringToDefault(arg[" ~ I.to!string ~ "])";
        }
        else static if(is(P[0] == DefaultValue!(wstring, false)))
        {
            enum add = 1;
            enum outadd = 0;
            const string arg = "fromStringToSkip(arg[" ~ I.to!string ~ "])";
        }
        else static if(is(P[0] == Value[]))
        {
            const string arg = "arg";
        }
        else static if(is(P[0] == Value))
        {
            enum add = 1;
            enum outadd = 0;
            const string arg = "arg[" ~ I.to!string ~ "]";
        }
        else static if(is(P[0] == DefaultValue!Value))
        {
            enum add = 1;
            enum outadd = 0;
            const string arg = "fromValueToDefault(arg[" ~ I.to!string ~ "])";
        }
        else static if(is(P[0] == DefaultValue!(Value, false)))
        {
            enum add = 1;
            enum outadd = 0;
            const string arg = "fromValueToSkip(arg[" ~ I.to!string ~ "])";
        }
        else
        {
            enum add = 1;
            enum outadd = 0;
            pragma(msg, P[0]);
            static assert(false, "Invalid type");
            const string arg = "";
        }
        static if(1 == P.length)
        {
            const string AddFuncArg = arg;
        }
        else
        {
            const string AddFuncArg = arg ~ ", " ~ AddFuncArg!(L - !add, N + add, M + 1, O + outadd, BFD, P[1..$]);
        }
    }
}
template OutArgsInit(BFD, int I = 0, int J = 0)
{
    alias param = BFD.ParameterType;
    static if(!param.length)
    {
        enum OutArgsInit = "";
    }
    else
    {
        enum tuple = BFD.ParameterStorageClass[I];
        static if(tuple & ParameterStorageClass.out_)
        {
            enum add = 1;
            enum ret1 = "ret[" ~ J.to!string ~ "].type = ";
            static if(is(param[I] == int))
            {
                enum ret2 = "ValueType.Integer;";
            }
            else static if(is(param[I] == DefaultValue!int))
            {
                enum ret2 = "ValueType.Integer;";
            }
            //else static if(is(param[I] == OptionalOutValue!int))
            //{
            //    enum ret2 = "ValueType.Integer;";
            //}
            else static if(is(param[I] == double))
            {
                enum ret2 = "ValueType.Double;";
            }
            else static if(is(param[I] == Value[]))
            {
                enum ret2 = "ValueType.Void;";
            }
            else static if(is(param[I] == wstring))
            {
                enum ret2 = "ValueType.String;";
            }
            else
            {
                static assert(false, "invalid type " ~ param[I].stringof); 
            }
            enum result = ret1 ~ ret2;
        }
        else
        {
            enum add = 0;
            enum result = "";
        }
        static if(param.length > I + 1)
        {
            enum OutArgsInit = result ~ OutArgsInit!(BFD, I + 1, J + add);
        }
        else
        {
            enum OutArgsInit = result;
        }
    }
}
template GetArgumentCount(BFD, int I = 0)
{
    alias param = BFD.ParameterType;
    static if(param.length <= I)
    {
        enum GetArgumentCount = 0;
    }
    else
    {
        enum tuple = BFD.ParameterStorageClass[I];
        static if(is(param[I] == PetitComputer))
        {
            enum add = 0 + 1;
        }
        else
        {
            static if(tuple & ParameterStorageClass.out_)
            {
                enum add = 0;
            }
            else
            {
                enum add = 1;
            }
        }
        static if(param.length > I + 1)
        {
            enum GetArgumentCount = add + GetArgumentCount!(BFD, I + 1);
        }
        else
        {
            enum GetArgumentCount = add;
        }
    }
}
template IsVariadic(BFD, int I = 0)
{
    alias param = BFD.ParameterType;
    static if(param.length == 0 || param.length <= I)
    {
        enum IsVariadic = false;
    }
    else static if(is(param[I] == Value[]))
    {
        enum IsVariadic = true;
    }
    else
    {
        enum IsVariadic = IsVariadic!(BFD, I + 1);
    }
}

