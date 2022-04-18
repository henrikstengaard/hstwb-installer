namespace HstWbInstaller.Core.IO.Pfs3.Blocks
{
    using System.Collections.Generic;

    public class LruCachedBlock : IEqualityComparer<LruCachedBlock>
    {
        public CachedBlock cblk;

        public LruCachedBlock(CachedBlock cblk)
        {
            this.cblk = cblk;
        }

        public bool Equals(LruCachedBlock x, LruCachedBlock y)
        {
            if (ReferenceEquals(x, y)) return true;
            if (ReferenceEquals(x, null)) return false;
            if (ReferenceEquals(y, null)) return false;
            if (x.GetType() != y.GetType()) return false;
            return Equals(x.cblk, y.cblk);
        }

        public int GetHashCode(LruCachedBlock obj)
        {
            return (obj.cblk != null ? obj.cblk.GetHashCode() : 0);
        }
    }
}