using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace buildtoc
{
    public class TOC : List<TOCItem>
    {


        public TOC()
        {

            this.Add(new TOCItem("Overview"));
            this.Add(new TOCItem("Get Started"));
            this.Add(new TOCItem("Plan & Design"));
            this.Add(new TOCItem("How To"));
            this.Add(new TOCItem("Reference"));
            this.Add(new TOCItem("Resources"));

            /*
             * Overview
            Get Started
            Plan/Design
            How To
            Reference
            Related
            Resources

            */
        }

    }
}
