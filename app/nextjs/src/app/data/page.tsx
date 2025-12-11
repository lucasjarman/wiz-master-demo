import { S3Client, ListObjectsV2Command } from "@aws-sdk/client-s3";
import { Database, FileText, AlertOctagon } from 'lucide-react';
import Link from 'next/link';

// Initialize S3 Client (picks up IAM Role from EKS Pod Identity / Instance Profile automatically)
const s3 = new S3Client({ region: process.env.AWS_REGION || "ap-southeast-2" });

async function getSensitiveData() {
    const bucketName = process.env.S3_BUCKET_NAME;

    if (!bucketName) {
        return { error: "S3_BUCKET_NAME environment variable not set." };
    }

    try {
        const command = new ListObjectsV2Command({ Bucket: bucketName });
        const response = await s3.send(command);
        return {
            bucket: bucketName,
            objects: response.Contents || []
        };
    } catch (error: unknown) {
        const msg = error instanceof Error ? error.message : String(error);
        return { error: msg };
    }
}

export default async function DataPage() {
    const data = await getSensitiveData();

    return (
        <div className="min-h-screen bg-slate-900 text-white p-8 font-sans">
            <div className="max-w-5xl mx-auto space-y-8">

                <header className="flex justify-between items-center border-b border-slate-700 pb-4">
                    <h1 className="text-3xl font-bold text-purple-400">Corporate Data</h1>
                    <Link href="/" className="text-slate-400 hover:text-white transition-colors">← Back to Home</Link>
                </header>

                {data.error ? (
                    <div className="p-6 bg-red-900/20 border border-red-500 rounded-lg flex gap-4 items-start">
                        <AlertOctagon className="w-6 h-6 text-red-500 mt-1" />
                        <div>
                            <h3 className="font-bold text-red-500">Access Denied / Error</h3>
                            <p className="text-red-200 text-sm mono mt-1">{data.error}</p>
                            <p className="text-slate-500 text-xs mt-4">
                                Debug: Ensure the Pod has the correct IAM Role attached and S3_BUCKET_NAME is set.
                            </p>
                        </div>
                    </div>
                ) : (
                    <div className="border border-slate-700 rounded-xl overflow-hidden bg-slate-800">
                        <div className="p-4 bg-slate-900/50 border-b border-slate-700 flex items-center gap-2">
                            <Database className="w-5 h-5 text-purple-400" />
                            <span className="font-mono text-sm text-slate-300">s3://{data.bucket}</span>
                        </div>

                        <ul className="divide-y divide-slate-700">
                            {data.objects?.map((obj) => (
                                <li key={obj.Key} className="p-4 hover:bg-slate-700/50 transition-colors flex items-center justify-between group">
                                    <div className="flex items-center gap-3">
                                        <FileText className="w-8 h-8 text-slate-500 group-hover:text-purple-400 transition-colors" />
                                        <div>
                                            <p className="font-medium text-slate-200">{obj.Key}</p>
                                            <p className="text-xs text-slate-500">{obj.LastModified?.toLocaleString()}</p>
                                        </div>
                                    </div>
                                    <div className="text-right">
                                        <span className="text-xs font-mono text-slate-500 bg-slate-900 px-2 py-1 rounded">
                                            {obj.Size ? (obj.Size / 1024).toFixed(1) + " KB" : "0 B"}
                                        </span>
                                    </div>
                                </li>
                            ))}
                        </ul>

                        <div className="p-4 bg-purple-900/10 border-t border-slate-700 text-center">
                            <p className="text-xs text-purple-300">
                                <span className="font-bold">DEMO NOTE:</span> Accessing this page proves the Pod has permissions to list the sensitive bucket.
                            </p>
                        </div>
                    </div>
                )}

            </div>
        </div>
    );
}
