// Galaga CPC for Windows: one .exe with the game and an Amstrad CPC emulator in it.
//
// The emulator (Caprice32, GPL), its ROMs and the game's disk are a zip embedded in this
// exe (tools/make_windows.py). On the first run it is unpacked to
// %LOCALAPPDATA%\GalagaCPC\<hash of the zip> - nothing is installed, and a new version
// of the exe unpacks beside the old one - then Caprice32 starts with the disk in drive A
// and types RUN"GALAGA. Arguments are passed on to Caprice32 (e.g. -a "..." to type
// something else, which replaces RUN"GALAGA).
//
// Built with the .NET Framework's own csc.exe, which every Windows 10/11 has.

using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Reflection;
using System.Security.Cryptography;
using System.Windows.Forms;

[assembly: AssemblyTitle("Galaga CPC")]
[assembly: AssemblyProduct("Galaga CPC")]
[assembly: AssemblyCopyright("Revive8bit 2026 - Vasper")]

static class Launcher
{
    [STAThread]
    static int Main(string[] args)
    {
        try
        {
            byte[] zip;
            using (var res = Assembly.GetExecutingAssembly().GetManifestResourceStream("payload.zip"))
            using (var mem = new MemoryStream())
            {
                res.CopyTo(mem);
                zip = mem.ToArray();
            }
            string hash;
            using (var sha = SHA1.Create())
                hash = BitConverter.ToString(sha.ComputeHash(zip)).Replace("-", "").Substring(0, 12);
            string dir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "GalagaCPC", hash);
            string done = Path.Combine(dir, ".unpacked");
            if (!File.Exists(done))
            {
                if (Directory.Exists(dir))
                    Directory.Delete(dir, true);        // a half-finished earlier attempt
                Directory.CreateDirectory(dir);
                using (var mem = new MemoryStream(zip))
                using (var archive = new ZipArchive(mem))
                    archive.ExtractToDirectory(dir);
                File.WriteAllText(done, "");
            }

            string extra = string.Join(" ", args.Select(Quote));
            string type = args.Contains("-a") ? "" : " -a " + Quote("run\"galaga");
            var psi = new ProcessStartInfo(Path.Combine(dir, "cap32.exe"),
                "--cfg_file=" + Quote(Path.Combine(dir, "cap32.cfg")) + type
                + (extra.Length > 0 ? " " + extra : "")
                + " " + Quote(Path.Combine(dir, "galaga.dsk")));
            psi.WorkingDirectory = dir;
            psi.UseShellExecute = false;
            Process.Start(psi);
            return 0;
        }
        catch (Exception e)
        {
            MessageBox.Show("Galaga CPC could not start:\n\n" + e.Message, "Galaga CPC",
                            MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }

    // One argument for the C runtime's command-line parser: quotes round it, inner quotes
    // (and the backslashes before them) escaped.
    static string Quote(string arg)
    {
        var sb = new System.Text.StringBuilder("\"");
        int slashes = 0;
        foreach (char c in arg)
        {
            if (c == '\\') { slashes++; continue; }
            if (c == '"') sb.Append('\\', slashes * 2 + 1);
            else sb.Append('\\', slashes);
            slashes = 0;
            sb.Append(c);
        }
        sb.Append('\\', slashes * 2);
        return sb.Append('"').ToString();
    }
}
